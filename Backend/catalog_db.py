"""Persistencia para catálogo, feed, historias, perfiles e intercambios (SQLite o Supabase/Postgres)."""

from __future__ import annotations

import json
import math
import os
from datetime import datetime, timezone
from typing import Any

from database import column_names, get_catalog_connection, is_postgres, table_exists
from service_categories import (
    catalog_sql_like_patterns,
    list_categories,
    resolve_trade,
    split_requirements,
)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "instance", "alworki.db")


def _utc_now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def _parse_json(val: Any, default: Any = None) -> Any:
    if val is None:
        return default if default is not None else {}
    if isinstance(val, (dict, list)):
        return val
    if isinstance(val, str) and not val.strip():
        return default if default is not None else {}
    return json.loads(val)


def get_conn():
    return get_catalog_connection()


def init_db() -> None:
    conn = get_conn()
    if not is_postgres():
        conn.executescript(
        """
        CREATE TABLE IF NOT EXISTS cards (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            image_url TEXT NOT NULL,
            category TEXT NOT NULL,
            price INTEGER NOT NULL DEFAULT 1,
            rating REAL NOT NULL DEFAULT 4.5,
            reviews_count INTEGER NOT NULL DEFAULT 0,
            last_updated TEXT NOT NULL,
            owner_user_id INTEGER
        );

        CREATE TABLE IF NOT EXISTS feed_posts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_json TEXT NOT NULL,
            image_url TEXT NOT NULL,
            description TEXT NOT NULL,
            likes INTEGER NOT NULL DEFAULT 0,
            comments INTEGER NOT NULL DEFAULT 0,
            cost INTEGER NOT NULL DEFAULT 1,
            cost_type TEXT NOT NULL DEFAULT 'favor',
            card_id INTEGER,
            card_title TEXT,
            location TEXT,
            timestamp TEXT NOT NULL,
            liked INTEGER NOT NULL DEFAULT 0,
            saved INTEGER NOT NULL DEFAULT 0
        );

        CREATE TABLE IF NOT EXISTS stories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_json TEXT NOT NULL,
            caption TEXT NOT NULL,
            image_url TEXT NOT NULL,
            card_id INTEGER,
            card_title TEXT,
            timestamp TEXT NOT NULL,
            duration INTEGER NOT NULL DEFAULT 5,
            viewed INTEGER NOT NULL DEFAULT 0
        );

        CREATE TABLE IF NOT EXISTS profiles (
            user_id INTEGER PRIMARY KEY,
            data_json TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS exchange_requests (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'pendiente',
            post_id INTEGER,
            card_id INTEGER,
            offer_title TEXT,
            created_at TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS projects (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            description TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'planificacion',
            partner_name TEXT NOT NULL DEFAULT ''
        );

        CREATE TABLE IF NOT EXISTS quotes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            provider_id INTEGER NOT NULL,
            client_id INTEGER,
            tracking_number TEXT NOT NULL UNIQUE,
            services_json TEXT NOT NULL,
            materials_json TEXT NOT NULL,
            quote_date TEXT NOT NULL,
            time_slot TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'pendiente',
            created_at TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS reports (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            provider_id INTEGER,
            tracking_number TEXT NOT NULL,
            action TEXT NOT NULL,
            created_at TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS notifications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            from_user_json TEXT,
            message TEXT NOT NULL,
            time_ago TEXT NOT NULL,
            is_recent INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS message_threads (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            peer_json TEXT NOT NULL,
            last_message TEXT NOT NULL,
            time_label TEXT NOT NULL,
            unread INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL
        );
        """
        )
    if is_postgres() and not table_exists(conn, "cards"):
        raise RuntimeError(
            "DATABASE_URL configurado pero faltan tablas. "
            "Ejecuta supabase/migrations/001_alworki_schema.sql en tu proyecto Supabase."
        )
    if conn.execute("SELECT COUNT(*) AS c FROM cards").fetchone()["c"] == 0:
        _seed(conn)
    _ensure_quote_columns(conn)
    _ensure_location_columns(conn)
    _seed_location_data(conn)
    _ensure_category_columns(conn)
    _ensure_exchange_columns(conn)
    _seed_extra_profession_cards(conn)
    _ensure_social_tables(conn)
    _ensure_demo_profiles(conn)
    _seed_demo_order(conn)
    _seed_social_extras(conn)
    _ensure_identity_table(conn)
    _ensure_follow_tables(conn)
    _ensure_project_columns(conn)
    conn.commit()
    conn.close()


def _ensure_follow_tables(conn) -> None:
    if is_postgres():
        return
    conn.executescript(
        """
        CREATE TABLE IF NOT EXISTS user_follows (
            follower_id INTEGER NOT NULL,
            followed_id INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            PRIMARY KEY (follower_id, followed_id)
        );
        CREATE TABLE IF NOT EXISTS project_follows (
            user_id INTEGER NOT NULL,
            project_id INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            PRIMARY KEY (user_id, project_id)
        );
        """
    )


def _ensure_social_tables(conn) -> None:
    if is_postgres():
        return
    conn.executescript(
        """
        CREATE TABLE IF NOT EXISTS contact_requests (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            requester_json TEXT NOT NULL,
            subtitle TEXT NOT NULL DEFAULT '',
            status TEXT NOT NULL DEFAULT 'pending',
            created_at TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS blocked_contacts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            blocked_json TEXT NOT NULL,
            created_at TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS chat_messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            thread_id INTEGER NOT NULL,
            sender TEXT NOT NULL,
            message_type TEXT NOT NULL DEFAULT 'text',
            body TEXT NOT NULL,
            meta_json TEXT,
            created_at TEXT NOT NULL
        );
        """
    )


def _bbox(center_lat: float, center_lng: float, radius_km: float) -> tuple[float, float, float, float]:
    """Cuadrado que contiene el círculo: min_lat, max_lat, min_lng, max_lng."""
    d_lat = radius_km / 111.0
    cos_lat = max(0.01, abs(math.cos(math.radians(center_lat))))
    d_lng = radius_km / (111.0 * cos_lat)
    return (
        center_lat - d_lat,
        center_lat + d_lat,
        center_lng - d_lng,
        center_lng + d_lng,
    )


def _ensure_location_columns(conn) -> None:
    for table in ("cards", "feed_posts"):
        cols = column_names(conn, table)
        if "lat" not in cols:
            conn.execute(f"ALTER TABLE {table} ADD COLUMN lat REAL")
        if "lng" not in cols:
            conn.execute(f"ALTER TABLE {table} ADD COLUMN lng REAL")


def _seed_location_data(conn) -> None:
    card_locs = {
        1: (19.4326, -99.1332),
        2: (19.4280, -99.1400),
        3: (20.6597, -103.3496),
        4: (19.4350, -99.1280),
        5: (25.6866, -100.3161),
    }
    for card_id, (lat, lng) in card_locs.items():
        conn.execute(
            "UPDATE cards SET lat = ?, lng = ? WHERE id = ? AND (lat IS NULL OR lng IS NULL)",
            (lat, lng, card_id),
        )

    feed_locs = {
        1: (19.4326, -99.1332),
        2: (20.6597, -103.3496),
        3: (25.6866, -100.3161),
    }
    for post_id, (lat, lng) in feed_locs.items():
        conn.execute(
            "UPDATE feed_posts SET lat = ?, lng = ? WHERE id = ? AND (lat IS NULL OR lng IS NULL)",
            (lat, lng, post_id),
        )


def _ensure_category_columns(conn) -> None:
    cols = column_names(conn, "feed_posts")
    if "category" not in cols:
        conn.execute("ALTER TABLE feed_posts ADD COLUMN category TEXT")


def _ensure_exchange_columns(conn) -> None:
    cols = column_names(conn, "exchange_requests")
    if "target_user_id" not in cols:
        conn.execute("ALTER TABLE exchange_requests ADD COLUMN target_user_id INTEGER")


def _ensure_project_columns(conn) -> None:
    cols = column_names(conn, "projects")
    additions = {
        "tracking_number": "TEXT",
        "delivery_status": "TEXT NOT NULL DEFAULT 'solicitado'",
        "requirements_json": "TEXT NOT NULL DEFAULT '[]'",
        "events_json": "TEXT NOT NULL DEFAULT '[]'",
        "delivery_json": "TEXT",
        "partner_user_id": "INTEGER",
        "category": "TEXT",
        "exchange_id": "INTEGER",
    }
    for name, col_def in additions.items():
        if name not in cols:
            conn.execute(f"ALTER TABLE projects ADD COLUMN {name} {col_def}")
    rows = conn.execute("SELECT id, status, tracking_number, delivery_status FROM projects").fetchall()
    for row in rows:
        if row["tracking_number"]:
            continue
        tracking = f"AW-P-{int(row['id']):06d}"
        delivery = _status_to_delivery(row["status"])
        conn.execute(
            "UPDATE projects SET tracking_number = ?, delivery_status = ? WHERE id = ?",
            (tracking, delivery, row["id"]),
        )


def _seed_extra_profession_cards(conn) -> None:
    today = datetime.utcnow().strftime("%Y-%m-%d")
    extras = [
        (6, "Enfermería a domicilio", "Curaciones, medicación y cuidados básicos.", "background5.png", "Salud y cuidado", 3, 4.9, 19, 19.4300, -99.1350),
        (7, "Cuidado de adulto mayor", "Acompañamiento y asistencia diaria.", "background5.png", "Salud y cuidado", 2, 4.8, 14, 19.4340, -99.1300),
        (8, "Consulta veterinaria", "Revisión general y vacunación de mascotas.", "background2.png", "Mascotas", 2, 4.9, 27, 19.4290, -99.1380),
        (9, "Plomería express", "Fugas, destapes y instalaciones menores.", "background4.png", "Hogar y reparaciones", 3, 4.7, 33, 19.4310, -99.1320),
        (10, "Limpieza profunda", "Hogar u oficina, productos incluidos.", "background2.png", "Hogar y reparaciones", 2, 4.6, 41, 19.4270, -99.1410),
        (11, "Niñera certificada", "Cuidado infantil por horas o fines de semana.", "background1.png", "Educación y cuidado infantil", 2, 4.9, 22, 19.4335, -99.1345),
        (12, "Electricista residencial", "Contactos, luminarias y tableros.", "background4.png", "Hogar y reparaciones", 3, 4.8, 19, 19.4360, -99.1290),
        (13, "Fisioterapia en casa", "Sesiones de rehabilitación y movilidad.", "background5.png", "Salud y cuidado", 3, 4.7, 11, 19.4315, -99.1365),
        (14, "Fotografía de eventos", "Bodas, XV años y sesiones familiares.", "background3.png", "Eventos", 4, 4.9, 16, 19.4285, -99.1395),
        (15, "Soporte técnico", "PC, redes e instalación de software.", "background1.png", "Tecnología", 2, 4.6, 28, 19.4320, -99.1310),
        (16, "Carpintero a domicilio", "Muebles a medida, closets y reparación en madera. Herramientas propias.", "background4.png", "Hogar y reparaciones", 3, 4.9, 36, 19.4330, -99.1335),
        (17, "Carpintería de muebles", "Closets, mesas y restauración en madera sólida.", "background4.png", "Hogar y reparaciones", 3, 4.7, 21, 19.4180, -99.1600),
        (18, "Carpintero de obra", "Puertas, marcos y acabados. No hace muebles a medida.", "background4.png", "Hogar y reparaciones", 2, 4.5, 12, 19.3900, -99.1800),
    ]
    for row in extras:
        exists = conn.execute("SELECT id FROM cards WHERE id = ?", (row[0],)).fetchone()
        if exists:
            conn.execute(
                "UPDATE cards SET lat = ?, lng = ? WHERE id = ? AND (lat IS NULL OR lng IS NULL)",
                (row[8], row[9], row[0]),
            )
            continue
        conn.execute(
            """
            INSERT INTO cards (id, title, description, image_url, category, price, rating, reviews_count, last_updated, lat, lng)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (*row[:8], today, row[8], row[9]),
        )


def _ensure_quote_columns(conn) -> None:
    cols = column_names(conn, "quotes")
    additions = {
        "title": "TEXT NOT NULL DEFAULT ''",
        "provider_name": "TEXT NOT NULL DEFAULT ''",
        "provider_avatar": "TEXT NOT NULL DEFAULT 'users/user.jpg'",
        "line_items_json": "TEXT NOT NULL DEFAULT '[]'",
        "requirements_json": "TEXT NOT NULL DEFAULT '[]'",
        "activities_json": "TEXT NOT NULL DEFAULT '[]'",
        "delivery_json": "TEXT",
        "total_al": "INTEGER NOT NULL DEFAULT 0",
        "shipping_cost": "INTEGER NOT NULL DEFAULT 0",
        "delivery_date": "TEXT",
        "order_start_date": "TEXT",
        "client_review_json": "TEXT",
        "provider_review_json": "TEXT",
    }
    for name, col_def in additions.items():
        if name not in cols:
            conn.execute(f"ALTER TABLE quotes ADD COLUMN {name} {col_def}")


def _seed(conn) -> None:
    demo_user_id = _ensure_demo_user(conn)
    cards = [
        (1, "Clases de inglés conversacional", "Práctica oral. Intercambio por otro favor.", "background1.png", "Educación", 2, 4.9, 31),
        (2, "Paseo de mascotas", "Paseos 45–60 min con fotos.", "background2.png", "Cuidado animal", 1, 4.8, 24),
        (3, "Clases de guitarra básica", "Presencial u online.", "background3.png", "Música", 2, 4.7, 18),
        (4, "Reparaciones menores del hogar", "Enchufes, bisagras, estanterías.", "background4.png", "Hogar", 3, 4.6, 15),
        (5, "Comida casera / meal prep", "2–3 raciones saludables.", "background5.png", "Gastronomía", 2, 4.5, 22),
    ]
    today = datetime.utcnow().strftime("%Y-%m-%d")
    for c in cards:
        conn.execute(
            """
            INSERT INTO cards (id, title, description, image_url, category, price, rating, reviews_count, last_updated)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (*c, today),
        )

    feed = [
        (
            json.dumps({"id": 1, "name": "Laura M.", "avatar": "users/1.jpg", "verified": True, "following": False}),
            "background1.png",
            "Ofrezco 2h de inglés a la semana. Busco paseo de perro los martes. #intercambio",
            342, 28, 2, "horas favor", 1, "Clases de inglés conversacional", "Ciudad de México", "2024-01-15T10:30:00Z",
        ),
        (
            json.dumps({"id": 2, "name": "Diego R.", "avatar": "users/2.jpg", "verified": False, "following": False}),
            "background2.png",
            "Paseo responsable. Intercambio por clases de guitarra.",
            198, 12, 1, "paseo", 2, "Paseo de mascotas", "Guadalajara", "2024-01-14T15:45:00Z",
        ),
        (
            json.dumps({"id": 3, "name": "Sofía K.", "avatar": "users/3.jpg", "verified": True, "following": False}),
            "background3.png",
            "Primera clase gratis. A cambio meal prep del fin de semana.",
            521, 45, 2, "horas favor", 3, "Clases de guitarra básica", "Monterrey", "2024-01-13T09:15:00Z",
        ),
    ]
    for row in feed:
        conn.execute(
            """
            INSERT INTO feed_posts (user_json, image_url, description, likes, comments, cost, cost_type, card_id, card_title, location, timestamp)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            row,
        )

    stories = [
        (
            json.dumps({"id": 1, "name": "Laura", "avatar": "users/1.jpg", "verified": True}),
            "Nueva oferta: inglés ↔ paseos",
            "background1.png", 1, "Clases de inglés", "2024-01-15T10:30:00Z", 5, 0,
        ),
        (
            json.dumps({"id": 2, "name": "Diego", "avatar": "users/2.jpg", "verified": False}),
            "Disponible fines de semana",
            "background2.png", 2, "Paseo de mascotas", "2024-01-15T09:15:00Z", 5, 0,
        ),
    ]
    for s in stories:
        conn.execute(
            """
            INSERT INTO stories (user_json, caption, image_url, card_id, card_title, timestamp, duration, viewed)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """,
            s,
        )

    profile = {
        "id": demo_user_id,
        "name": "Perfil demo Alworki",
        "verified": True,
        "avatar": "users/1.jpg",
        "contacts": 12,
        "professions": ["Ofrezco favores", "Busco intercambios"],
        "localContacts": 8,
        "remoteContacts": 4,
        "localAvailable": True,
        "remoteAvailable": True,
        "skills": [{"id": 1, "name": "Inglés B2"}, {"id": 2, "name": "Paseo de perros"}],
        "portfolio": [],
        "reviews": [],
    }
    conn.execute(
        "INSERT INTO profiles (user_id, data_json) VALUES (?, ?)",
        (demo_user_id, json.dumps(profile)),
    )

    conn.execute(
        """
        INSERT INTO projects (user_id, name, description, status, partner_name)
        VALUES (?, 'Inglés ↔ Paseos', '2h inglés semanal a cambio de paseos', 'en_curso', 'Laura M.')
        """,
        (demo_user_id,),
    )


def _ensure_demo_user(conn) -> int:
    if is_postgres():
        row = conn.execute(
            "SELECT id FROM app_users WHERE LOWER(email) = ?",
            ("demo@alworki.com",),
        ).fetchone()
        if row:
            return int(row["id"])
        cur = conn.execute(
            """
            INSERT INTO app_users (email, password_hash, firstname, lastname)
            VALUES (?, '', 'Demo', 'Usuario')
            """,
            ("demo@alworki.com",),
        )
        return int(cur.lastrowid)
    return 1


def _card_row(row: Any) -> dict[str, Any]:
    keys = row.keys()
    return {
        "id": row["id"],
        "title": row["title"],
        "description": row["description"],
        "image_url": row["image_url"],
        "category": row["category"],
        "price": row["price"],
        "rating": row["rating"],
        "reviews_count": row["reviews_count"],
        "last_updated": row["last_updated"],
        "lat": row["lat"] if "lat" in keys else None,
        "lng": row["lng"] if "lng" in keys else None,
        "ownerUserId": row["owner_user_id"] if "owner_user_id" in keys else None,
    }


def list_cards() -> list[dict[str, Any]]:
    conn = get_conn()
    rows = conn.execute("SELECT * FROM cards ORDER BY id").fetchall()
    conn.close()
    return [_card_row(r) for r in rows]


def list_service_categories() -> list[dict[str, Any]]:
    return list_categories()


def search_cards(
    query: str = "",
    lat: float | None = None,
    lng: float | None = None,
    radius_km: float = 10.0,
    requirements: Any = None,
    trade: str = "",
    require_all: bool = False,
) -> list[dict[str, Any]]:
    return match_jobs(
        query=query,
        lat=lat,
        lng=lng,
        radius_km=radius_km,
        requirements=requirements,
        trade=trade,
        require_all=require_all,
    )


def match_jobs(
    query: str = "",
    lat: float | None = None,
    lng: float | None = None,
    radius_km: float = 15.0,
    requirements: Any = None,
    trade: str = "",
    require_all: bool = False,
) -> list[dict[str, Any]]:
    """Oficio + requisitos + más cercano. Ej.: carpintero cerca que haga muebles a medida."""
    conn = get_conn()
    sql = "SELECT * FROM cards WHERE 1=1"
    params: list[Any] = []
    q = (trade or query or "").strip()
    if q:
        patterns = list(dict.fromkeys([f"%{q.lower()}%", *catalog_sql_like_patterns(q)]))
        or_parts: list[str] = []
        for pattern in patterns[:24]:
            or_parts.append("(lower(title) LIKE ? OR lower(description) LIKE ? OR lower(category) LIKE ?)")
            params.extend([pattern, pattern, pattern])
        sql += f" AND ({' OR '.join(or_parts)})"
    if lat is not None and lng is not None:
        min_lat, max_lat, min_lng, max_lng = _bbox(lat, lng, radius_km)
        sql += " AND lat IS NOT NULL AND lng IS NOT NULL"
        sql += " AND lat BETWEEN ? AND ? AND lng BETWEEN ? AND ?"
        params.extend([min_lat, max_lat, min_lng, max_lng])
    sql += " ORDER BY id"
    rows = conn.execute(sql, tuple(params)).fetchall()
    conn.close()

    reqs = split_requirements(requirements)
    resolved = resolve_trade(trade or query)
    trade_terms = [t.lower() for t in (resolved or {}).get("terms", [])]
    ranked: list[dict[str, Any]] = []
    for row in rows:
        item = _card_row(row)
        blob = " ".join(
            [
                str(item.get("title") or ""),
                str(item.get("description") or ""),
                str(item.get("category") or ""),
            ]
        ).lower()
        matched = [r for r in reqs if r in blob]
        meets = bool(reqs) and len(matched) == len(reqs)
        if require_all and reqs and not meets:
            continue
        distance = None
        if lat is not None and lng is not None and item.get("lat") is not None and item.get("lng") is not None:
            distance = round(_approx_km(lat, lng, float(item["lat"]), float(item["lng"])), 2)
        trade_hit = 1.0 if (not trade_terms or any(t in blob for t in trade_terms)) else 0.2
        req_ratio = (len(matched) / len(reqs)) if reqs else 0.5
        rating = float(item.get("rating") or 0)
        distance_penalty = (distance or 8.0) * 1.6
        score = trade_hit * 40 + req_ratio * 35 + rating * 3 - distance_penalty
        item["distanceKm"] = distance
        item["matchScore"] = round(score, 2)
        item["matchedRequirements"] = matched
        item["meetsRequirements"] = meets if reqs else True
        item["trade"] = (resolved or {}).get("label")
        ranked.append(item)

    ranked.sort(
        key=lambda c: (
            0 if c.get("meetsRequirements") else 1,
            c.get("distanceKm") if c.get("distanceKm") is not None else 999,
            -(c.get("matchScore") or 0),
        )
    )
    return ranked


def _approx_km(from_lat: float, from_lng: float, to_lat: float, to_lng: float) -> float:
    d_lat = (to_lat - from_lat) * 111.0
    d_lng = (to_lng - from_lng) * 111.0 * math.cos(math.radians(from_lat))
    return math.hypot(d_lat, d_lng)


def get_card(card_id: int) -> dict[str, Any] | None:
    conn = get_conn()
    row = conn.execute("SELECT * FROM cards WHERE id = ?", (card_id,)).fetchone()
    conn.close()
    return _card_row(row) if row else None


def create_card(data: dict[str, Any], owner_user_id: int | None = None) -> dict[str, Any]:
    conn = get_conn()
    cur = conn.cursor()
    cur.execute(
        """
        INSERT INTO cards (title, description, image_url, category, price, rating, reviews_count, last_updated, owner_user_id)
        VALUES (?, ?, ?, ?, ?, ?, 0, ?, ?)
        """,
        (
            data["title"],
            data["description"],
            data.get("image_url", "background1.png"),
            data.get("category", "General"),
            int(data.get("price", 1)),
            float(data.get("rating", 4.5)),
            datetime.utcnow().strftime("%Y-%m-%d"),
            owner_user_id,
        ),
    )
    conn.commit()
    card_id = cur.lastrowid
    row = conn.execute("SELECT * FROM cards WHERE id = ?", (card_id,)).fetchone()
    conn.close()
    return _card_row(row)


def _feed_row(row: Any) -> dict[str, Any]:
    user = _parse_json(row["user_json"])
    return {
        "id": row["id"],
        "user": user,
        "image_url": row["image_url"],
        "description": row["description"],
        "likes": row["likes"],
        "comments": row["comments"],
        "cost": row["cost"],
        "cost_type": row["cost_type"],
        "card_id": row["card_id"],
        "card_title": row["card_title"],
        "location": row["location"] or "",
        "timestamp": row["timestamp"],
        "lat": row["lat"] if "lat" in row.keys() else None,
        "lng": row["lng"] if "lng" in row.keys() else None,
        "category": row["category"] if "category" in row.keys() and row["category"] else "",
        "recommended": False,
        "saved": bool(row["saved"]),
        "showMenu": False,
        "liked": bool(row["liked"]),
    }


def list_feed(viewer_id: int | None = None) -> list[dict[str, Any]]:
    conn = get_conn()
    rows = conn.execute("SELECT * FROM feed_posts ORDER BY timestamp DESC").fetchall()
    following: set[int] = set()
    if viewer_id:
        following = {
            int(r["followed_id"])
            for r in conn.execute(
                "SELECT followed_id FROM user_follows WHERE follower_id = ?",
                (viewer_id,),
            ).fetchall()
        }
    conn.close()
    posts = []
    for r in rows:
        post = _feed_row(r)
        user = post.get("user") or {}
        if following and user.get("id") in following:
            user = {**user, "following": True}
            post["user"] = user
        posts.append(post)
    return posts


def list_feed_personalized(
    user_id: int,
    *,
    proximity_enabled: bool = False,
    center_lat: float | None = None,
    center_lng: float | None = None,
    radius_km: float = 15.0,
) -> list[dict[str, Any]]:
    from feed_ranking import build_signals_from_profile, rank_feed_posts

    posts = list_feed(user_id)
    profile = get_profile(user_id)
    contact_ids = [c["peerId"] for c in list_contacts(user_id) if c.get("peerId") is not None]
    signals = build_signals_from_profile(
        user_id,
        profile,
        contact_user_ids=contact_ids,
        proximity_enabled=proximity_enabled,
        center_lat=center_lat,
        center_lng=center_lng,
        radius_km=radius_km,
    )
    return rank_feed_posts(posts, signals)


def list_profile_suggestions(
    user_id: int,
    *,
    limit: int = 12,
) -> list[dict[str, Any]]:
    from feed_ranking import build_signals_from_profile, rank_profile_suggestions

    profile = get_profile(user_id)
    contact_ids = [c["peerId"] for c in list_contacts(user_id) if c.get("peerId") is not None]
    signals = build_signals_from_profile(user_id, profile, contact_user_ids=contact_ids)

    candidates: list[dict[str, Any]] = []
    seen_users: set[int] = set()

    for story in list_stories():
        uid = (story.get("user") or {}).get("id")
        if uid is None or uid in seen_users:
            continue
        seen_users.add(uid)
        candidates.append(
            {
                "userId": uid,
                "user": story["user"],
                "caption": story.get("caption", ""),
                "card_title": story.get("card_title", ""),
                "image_url": story.get("image_url", ""),
                "timestamp": story.get("timestamp", ""),
                "story_id": story.get("id"),
            }
        )

    for post in list_feed():
        uid = (post.get("user") or {}).get("id")
        if uid is None or uid in seen_users:
            continue
        seen_users.add(uid)
        candidates.append(
            {
                "userId": uid,
                "user": post["user"],
                "caption": (post.get("description") or "")[:80],
                "card_title": post.get("card_title", ""),
                "image_url": post.get("image_url", ""),
                "timestamp": post.get("timestamp", ""),
                "story_id": None,
            }
        )

    ranked = rank_profile_suggestions(candidates, signals, limit=limit)
    return ranked


def create_feed_post(data: dict[str, Any]) -> dict[str, Any]:
    conn = get_conn()
    user = data.get("user") or {"id": 0, "name": "Usuario", "avatar": "users/user.jpg", "verified": False, "following": False}
    ts = data.get("timestamp") or _utc_now_iso()
    cur = conn.cursor()
    category = data.get("category") or ""
    cur.execute(
        """
        INSERT INTO feed_posts (user_json, image_url, description, likes, comments, cost, cost_type, card_id, card_title, location, timestamp, category)
        VALUES (?, ?, ?, 0, 0, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            json.dumps(user),
            data.get("image_url", "background1.png"),
            data["description"],
            int(data.get("cost", 1)),
            data.get("cost_type", "favor"),
            data.get("card_id"),
            data.get("card_title", ""),
            data.get("location", ""),
            ts,
            category,
        ),
    )
    conn.commit()
    post_id = cur.lastrowid
    row = conn.execute("SELECT * FROM feed_posts WHERE id = ?", (post_id,)).fetchone()
    conn.close()
    return _feed_row(row)


def toggle_feed_like(post_id: int) -> dict[str, Any] | None:
    conn = get_conn()
    row = conn.execute("SELECT * FROM feed_posts WHERE id = ?", (post_id,)).fetchone()
    if not row:
        conn.close()
        return None
    liked = not bool(row["liked"])
    likes = row["likes"] + (1 if liked else -1)
    conn.execute(
        "UPDATE feed_posts SET liked = ?, likes = ? WHERE id = ?",
        (1 if liked else 0, max(0, likes), post_id),
    )
    conn.commit()
    row = conn.execute("SELECT * FROM feed_posts WHERE id = ?", (post_id,)).fetchone()
    conn.close()
    return _feed_row(row)


def toggle_feed_save(post_id: int) -> dict[str, Any] | None:
    conn = get_conn()
    row = conn.execute("SELECT * FROM feed_posts WHERE id = ?", (post_id,)).fetchone()
    if not row:
        conn.close()
        return None
    saved = not bool(row["saved"])
    conn.execute("UPDATE feed_posts SET saved = ? WHERE id = ?", (1 if saved else 0, post_id))
    conn.commit()
    row = conn.execute("SELECT * FROM feed_posts WHERE id = ?", (post_id,)).fetchone()
    conn.close()
    return _feed_row(row)


def _story_row(row: sqlite3.Row) -> dict[str, Any]:
    return {
        "id": row["id"],
        "user": _parse_json(row["user_json"]),
        "story_type": "image",
        "media_url": row["image_url"],
        "caption": row["caption"],
        "image_url": row["image_url"],
        "card_id": row["card_id"],
        "card_title": row["card_title"],
        "timestamp": row["timestamp"],
        "duration": row["duration"],
        "viewed": bool(row["viewed"]),
    }


def list_stories() -> list[dict[str, Any]]:
    conn = get_conn()
    rows = conn.execute("SELECT * FROM stories ORDER BY timestamp DESC").fetchall()
    conn.close()
    return [_story_row(r) for r in rows]


def mark_story_viewed(story_id: int) -> bool:
    conn = get_conn()
    cur = conn.execute("UPDATE stories SET viewed = 1 WHERE id = ?", (story_id,))
    conn.commit()
    ok = cur.rowcount > 0
    conn.close()
    return ok


def default_profile(user_id: int, name: str, email: str) -> dict[str, Any]:
    return {
        "id": user_id,
        "name": name or email.split("@")[0],
        "verified": False,
        "avatar": "users/user.jpg",
        "contacts": 0,
        "professions": [],
        "localContacts": 0,
        "remoteContacts": 0,
        "localAvailable": True,
        "remoteAvailable": True,
        "skills": [],
        "materials": [],
        "portfolio": [],
        "reviews": [],
        "feedSignals": {"trustedUserIds": [], "categoryAffinity": {}},
        "redCoins": 2,
        "blueCoins": 1,
    }


def ensure_profile(user_id: int, name: str = "", email: str = "") -> dict[str, Any]:
    conn = get_conn()
    row = conn.execute("SELECT data_json FROM profiles WHERE user_id = ?", (user_id,)).fetchone()
    if row:
        conn.close()
        return _parse_json(row["data_json"])
    prof = default_profile(user_id, name, email)
    conn.execute(
        "INSERT INTO profiles (user_id, data_json) VALUES (?, ?)",
        (user_id, json.dumps(prof)),
    )
    conn.commit()
    conn.close()
    return prof


def get_profile(user_id: int) -> dict[str, Any] | None:
    conn = get_conn()
    row = conn.execute("SELECT data_json FROM profiles WHERE user_id = ?", (user_id,)).fetchone()
    conn.close()
    return _parse_json(row["data_json"]) if row else None


def update_availability(user_id: int, local: bool | None, remote: bool | None) -> dict[str, Any] | None:
    prof = get_profile(user_id)
    if not prof:
        return None
    if local is not None:
        prof["localAvailable"] = local
    if remote is not None:
        prof["remoteAvailable"] = remote
    conn = get_conn()
    conn.execute(
        "UPDATE profiles SET data_json = ? WHERE user_id = ?",
        (json.dumps(prof), user_id),
    )
    conn.commit()
    conn.close()
    return prof


def update_profile_meta(user_id: int, data: dict[str, Any]) -> dict[str, Any] | None:
    prof = get_profile(user_id)
    if not prof:
        return None
    if "professions" in data:
        prof["professions"] = data["professions"]
    if "contacts" in data:
        prof["contacts"] = int(data["contacts"])
    if "verified" in data:
        prof["verified"] = bool(data["verified"])
    if "feedSignals" in data and isinstance(data["feedSignals"], dict):
        prof["feedSignals"] = data["feedSignals"]
    conn = get_conn()
    conn.execute(
        "UPDATE profiles SET data_json = ? WHERE user_id = ?",
        (json.dumps(prof), user_id),
    )
    conn.commit()
    conn.close()
    return prof


def _save_profile(user_id: int, prof: dict[str, Any]) -> dict[str, Any]:
    conn = get_conn()
    conn.execute(
        "UPDATE profiles SET data_json = ? WHERE user_id = ?",
        (json.dumps(prof), user_id),
    )
    conn.commit()
    conn.close()
    return prof


def add_skill(user_id: int, name: str) -> dict[str, Any] | None:
    prof = get_profile(user_id) or ensure_profile(user_id)
    skills = list(prof.get("skills", []))
    new_id = max((int(s.get("id", 0)) for s in skills), default=0) + 1
    skill = {"id": new_id, "name": name}
    skills.append(skill)
    prof["skills"] = skills
    _save_profile(user_id, prof)
    return skill


def update_skill(user_id: int, skill_id: int, name: str) -> dict[str, Any] | None:
    prof = get_profile(user_id)
    if not prof:
        return None
    skills = prof.get("skills", [])
    for s in skills:
        if int(s.get("id")) == skill_id:
            s["name"] = name
            _save_profile(user_id, prof)
            return s
    return None


def remove_skill(user_id: int, skill_id: int) -> bool:
    prof = get_profile(user_id)
    if not prof:
        return False
    before = len(prof.get("skills", []))
    prof["skills"] = [s for s in prof.get("skills", []) if int(s.get("id")) != skill_id]
    if len(prof["skills"]) == before:
        return False
    _save_profile(user_id, prof)
    return True


def add_material(user_id: int, name: str) -> dict[str, Any] | None:
    prof = get_profile(user_id) or ensure_profile(user_id)
    materials = list(prof.get("materials", []))
    new_id = max((int(m.get("id", 0)) for m in materials), default=0) + 1
    item = {"id": new_id, "name": name}
    materials.append(item)
    prof["materials"] = materials
    _save_profile(user_id, prof)
    return item


def update_material(user_id: int, material_id: int, name: str) -> dict[str, Any] | None:
    prof = get_profile(user_id)
    if not prof:
        return None
    materials = prof.get("materials", [])
    for m in materials:
        if int(m.get("id")) == material_id:
            m["name"] = name
            _save_profile(user_id, prof)
            return m
    return None


def remove_material(user_id: int, material_id: int) -> bool:
    prof = get_profile(user_id)
    if not prof:
        return False
    before = len(prof.get("materials", []))
    prof["materials"] = [m for m in prof.get("materials", []) if int(m.get("id")) != material_id]
    if len(prof["materials"]) == before:
        return False
    _save_profile(user_id, prof)
    return True


def add_portfolio_item(user_id: int, data: dict[str, Any]) -> dict[str, Any] | None:
    prof = get_profile(user_id) or ensure_profile(user_id)
    portfolio = list(prof.get("portfolio", []))
    new_id = max((int(p.get("id", 0)) for p in portfolio), default=0) + 1
    item = {
        "id": new_id,
        "title": data.get("title") or data.get("profession") or (data.get("description", "")[:48] or f"Trabajo {new_id}"),
        "description": data.get("description", ""),
        "image": data.get("image_url") or data.get("image", "background1.png"),
        "tag": data.get("tag", "LOCAL"),
        "category": data.get("category", ""),
        "profession": data.get("profession", ""),
        "priceMxn": int(data.get("price_mxn") or data.get("priceMxn") or 0),
        "likes": int(data.get("likes") or 10000),
        "comments": int(data.get("comments") or 100),
        "shares": int(data.get("shares") or 35),
        "location": data.get("location", "México"),
    }
    portfolio.append(item)
    prof["portfolio"] = portfolio
    conn = get_conn()
    conn.execute(
        "UPDATE profiles SET data_json = ? WHERE user_id = ?",
        (json.dumps(prof), user_id),
    )
    conn.commit()
    conn.close()
    return prof


def list_exchanges(user_id: int) -> list[dict[str, Any]]:
    conn = get_conn()
    rows = conn.execute(
        """
        SELECT * FROM exchange_requests
        WHERE user_id = ? OR target_user_id = ? OR target_user_id IS NULL
        ORDER BY created_at DESC
        """,
        (user_id, user_id),
    ).fetchall()
    conn.close()
    return [_exchange_row(r) for r in rows]


def _exchange_row(row) -> dict[str, Any]:
    keys = row.keys()
    requester = row["user_id"]
    target = row["target_user_id"] if "target_user_id" in keys else None
    return {
        "id": row["id"],
        "title": row["title"],
        "description": row["description"],
        "status": row["status"],
        "createdAt": row["created_at"],
        "postId": row["post_id"],
        "cardId": row["card_id"],
        "offerTitle": row["offer_title"],
        "userId": requester,
        "targetUserId": target,
    }


def _resolve_exchange_target(data: dict[str, Any]) -> int | None:
    raw = data.get("target_user_id") or data.get("targetUserId")
    if raw is not None:
        try:
            return int(raw)
        except (TypeError, ValueError):
            return None
    card_id = data.get("card_id") or data.get("cardId")
    if card_id:
        card = get_card(int(card_id))
        owner = (card or {}).get("ownerUserId")
        if owner is not None:
            return int(owner)
    post_id = data.get("post_id") or data.get("postId")
    if post_id:
        post = get_feed_post(int(post_id))
        user = (post or {}).get("user") or {}
        if user.get("id") is not None:
            return int(user["id"])
    return None


def create_exchange(user_id: int, data: dict[str, Any]) -> dict[str, Any]:
    target = _resolve_exchange_target(data)
    if target is not None and int(target) == int(user_id):
        raise ValueError("No puedes solicitar un intercambio a ti mismo")
    conn = get_conn()
    cur = conn.cursor()
    cur.execute(
        """
        INSERT INTO exchange_requests
            (user_id, title, description, status, post_id, card_id, offer_title, created_at, target_user_id)
        VALUES (?, ?, ?, 'pendiente', ?, ?, ?, ?, ?)
        """,
        (
            user_id,
            data["title"],
            data.get("description", ""),
            data.get("post_id") or data.get("postId"),
            data.get("card_id") or data.get("cardId"),
            data.get("offer_title") or data.get("offerTitle"),
            _utc_now_iso(),
            target,
        ),
    )
    conn.commit()
    row = conn.execute("SELECT * FROM exchange_requests WHERE id = ?", (cur.lastrowid,)).fetchone()
    conn.close()
    return _exchange_row(row)


ALLOWED_EXCHANGE_TRANSITIONS = {
    "pendiente": {"aceptada", "rechazada"},
    "aceptada": {"completada", "rechazada"},
    "rechazada": set(),
    "completada": set(),
}


def get_exchange(exchange_id: int) -> dict[str, Any] | None:
    conn = get_conn()
    row = conn.execute("SELECT * FROM exchange_requests WHERE id = ?", (exchange_id,)).fetchone()
    conn.close()
    return _exchange_row(row) if row else None


def update_exchange_status(exchange_id: int, actor_id: int, status: str) -> dict[str, Any]:
    wanted = (status or "").strip().lower()
    if wanted not in {"aceptada", "rechazada", "completada"}:
        raise ValueError("status inválido")

    conn = get_conn()
    row = conn.execute("SELECT * FROM exchange_requests WHERE id = ?", (exchange_id,)).fetchone()
    if not row:
        conn.close()
        raise KeyError("not_found")

    current = _exchange_row(row)
    requester = int(current["userId"])
    target = int(current["targetUserId"]) if current.get("targetUserId") is not None else None
    participants = {requester} if target is None else {requester, target}
    if wanted == "aceptada" and current["status"] == "pendiente":
        if target is None:
            if actor_id == requester:
                conn.close()
                raise PermissionError("un tercero debe aceptar un intercambio abierto")
        elif actor_id != target:
            conn.close()
            raise PermissionError("solo el profesional destinatario puede aceptar")
    elif actor_id not in participants:
        conn.close()
        raise PermissionError("forbidden")

    if wanted not in ALLOWED_EXCHANGE_TRANSITIONS.get(current["status"], set()):
        conn.close()
        raise ValueError(f"No se puede pasar de {current['status']} a {wanted}")

    if wanted == "aceptada" and target is None:
        conn.execute(
            "UPDATE exchange_requests SET status = ?, target_user_id = ? WHERE id = ?",
            (wanted, actor_id, exchange_id),
        )
        target = actor_id
    else:
        conn.execute(
            "UPDATE exchange_requests SET status = ? WHERE id = ?",
            (wanted, exchange_id),
        )
    if wanted == "aceptada":
        partner = target if actor_id == requester else requester
        partner_name = f"Usuario {partner}" if partner is not None else "Pendiente"
        events_a = [
            _project_event("solicitado", "Intercambio solicitado", requester),
            _project_event("asignado", "Intercambio aceptado", actor_id),
            _project_event("en_trabajo", "Trabajo en curso", actor_id),
        ]
        _insert_tracked_project(
            conn,
            user_id=requester,
            name=current["title"],
            description=current["description"],
            status="en_curso",
            partner_name=partner_name,
            partner_user_id=target,
            delivery_status="en_trabajo",
            events=events_a,
            exchange_id=exchange_id,
        )
        if target is not None:
            _insert_tracked_project(
                conn,
                user_id=target,
                name=current["title"],
                description=current["description"],
                status="en_curso",
                partner_name=f"Usuario {requester}",
                partner_user_id=requester,
                delivery_status="en_trabajo",
                events=list(events_a),
                exchange_id=exchange_id,
            )
    conn.commit()
    updated = conn.execute("SELECT * FROM exchange_requests WHERE id = ?", (exchange_id,)).fetchone()
    conn.close()
    return _exchange_row(updated)


def search_feed(query: str = "") -> list[dict[str, Any]]:
    q = (query or "").strip().lower()
    posts = list_feed()
    if not q:
        return posts
    out = []
    for post in posts:
        blob = " ".join(
            [
                str(post.get("description") or ""),
                str(post.get("card_title") or ""),
                str(post.get("location") or ""),
                str((post.get("user") or {}).get("name") or ""),
                str(post.get("category") or ""),
            ]
        ).lower()
        if q in blob:
            out.append(post)
    return out


def get_feed_post(post_id: int) -> dict[str, Any] | None:
    conn = get_conn()
    row = conn.execute("SELECT * FROM feed_posts WHERE id = ?", (post_id,)).fetchone()
    conn.close()
    return _feed_row(row) if row else None


DELIVERY_STEPS = ("solicitado", "asignado", "en_trabajo", "entregado", "confirmado")
ALLOWED_DELIVERY_TRANSITIONS = {
    "solicitado": {"asignado", "en_trabajo"},
    "asignado": {"en_trabajo"},
    "en_trabajo": {"entregado"},
    "entregado": {"confirmado"},
    "confirmado": set(),
}
STATUS_FROM_DELIVERY = {
    "solicitado": "planificacion",
    "asignado": "en_curso",
    "en_trabajo": "en_curso",
    "entregado": "en_curso",
    "confirmado": "completado",
}


def _status_to_delivery(status: str | None) -> str:
    return {
        "planificacion": "solicitado",
        "en_curso": "en_trabajo",
        "completado": "confirmado",
        "pausado": "asignado",
    }.get((status or "").strip(), "solicitado")


def _normalize_delivery_status(raw: str | None, fallback: str = "solicitado") -> str:
    value = (raw or "").strip().lower().replace("-", "_")
    aliases = {
        "planificacion": "solicitado",
        "en_curso": "en_trabajo",
        "encurso": "en_trabajo",
        "completado": "confirmado",
        "completada": "confirmado",
        "entregada": "entregado",
        "start": "en_trabajo",
        "deliver": "entregado",
        "confirm": "confirmado",
    }
    value = aliases.get(value, value)
    return value if value in DELIVERY_STEPS else fallback


def _project_event(kind: str, title: str, actor_id: int | None = None) -> dict[str, Any]:
    return {
        "type": kind,
        "title": title,
        "timestamp": _utc_now_iso(),
        "actorId": actor_id,
    }


def _next_project_tracking(conn) -> str:
    count = conn.execute("SELECT COUNT(*) AS c FROM projects").fetchone()["c"]
    year = datetime.now(timezone.utc).year
    return f"AW-P-{year}-{int(count) + 1:04d}"


def _row_value(row: Any, key: str, default: Any = None) -> Any:
    keys = row.keys()
    return row[key] if key in keys else default


def _project_row(row, *, followed: bool = False, viewer_id: int | None = None) -> dict[str, Any]:
    owner_id = int(row["user_id"])
    partner_id = _row_value(row, "partner_user_id")
    partner_id = int(partner_id) if partner_id is not None else None
    delivery_status = _normalize_delivery_status(
        _row_value(row, "delivery_status"),
        _status_to_delivery(row["status"]),
    )
    events = _parse_json(_row_value(row, "events_json"), [])
    if not isinstance(events, list):
        events = []
    requirements = _parse_json(_row_value(row, "requirements_json"), [])
    if not isinstance(requirements, list):
        requirements = []
    delivery = _parse_json(_row_value(row, "delivery_json"), None)
    tracking = _row_value(row, "tracking_number") or f"AW-P-{int(row['id']):06d}"
    participants = {owner_id}
    if partner_id is not None:
        participants.add(partner_id)
    viewer = int(viewer_id) if viewer_id is not None else None
    is_owner = viewer == owner_id
    is_partner = partner_id is not None and viewer == partner_id
    can_act = viewer in participants if viewer is not None else False
    return {
        "id": row["id"],
        "name": row["name"],
        "description": row["description"],
        "status": row["status"],
        "partnerName": row["partner_name"],
        "ownerUserId": owner_id,
        "partnerUserId": partner_id,
        "followed": followed,
        "trackingNumber": tracking,
        "deliveryStatus": delivery_status,
        "requirements": [str(r) for r in requirements],
        "events": events,
        "delivery": delivery if isinstance(delivery, dict) else None,
        "category": _row_value(row, "category") or "",
        "exchangeId": _row_value(row, "exchange_id"),
        "isOwner": is_owner,
        "isPartner": is_partner,
        "canStart": can_act and delivery_status in {"solicitado", "asignado"},
        "canDeliver": can_act and delivery_status == "en_trabajo",
        "canConfirm": is_owner and delivery_status == "entregado",
    }


def _insert_tracked_project(
    conn,
    *,
    user_id: int,
    name: str,
    description: str,
    status: str,
    partner_name: str,
    partner_user_id: int | None,
    delivery_status: str,
    events: list[dict[str, Any]],
    requirements: list[str] | None = None,
    category: str = "",
    exchange_id: int | None = None,
) -> int:
    tracking = _next_project_tracking(conn)
    cur = conn.cursor()
    cur.execute(
        """
        INSERT INTO projects (
            user_id, name, description, status, partner_name,
            tracking_number, delivery_status, requirements_json, events_json,
            partner_user_id, category, exchange_id
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            user_id,
            name,
            description,
            status,
            partner_name,
            tracking,
            delivery_status,
            json.dumps(requirements or []),
            json.dumps(events),
            partner_user_id,
            category,
            exchange_id,
        ),
    )
    return int(cur.lastrowid)


def list_projects(user_id: int) -> list[dict[str, Any]]:
    conn = get_conn()
    own = conn.execute(
        "SELECT * FROM projects WHERE user_id = ? ORDER BY id DESC",
        (user_id,),
    ).fetchall()
    followed_ids = {
        int(r["project_id"])
        for r in conn.execute(
            "SELECT project_id FROM project_follows WHERE user_id = ?",
            (user_id,),
        ).fetchall()
    }
    extra = []
    if followed_ids:
        placeholders = ",".join("?" * len(followed_ids))
        extra = conn.execute(
            f"SELECT * FROM projects WHERE id IN ({placeholders}) AND user_id != ? ORDER BY id DESC",
            (*followed_ids, user_id),
        ).fetchall()
    conn.close()
    items = [_project_row(r, followed=False, viewer_id=user_id) for r in own]
    items.extend(_project_row(r, followed=True, viewer_id=user_id) for r in extra)
    return items


def get_project(project_id: int, user_id: int | None = None) -> dict[str, Any] | None:
    conn = get_conn()
    row = conn.execute("SELECT * FROM projects WHERE id = ?", (project_id,)).fetchone()
    followed = False
    if row and user_id is not None:
        followed = (
            conn.execute(
                "SELECT 1 FROM project_follows WHERE user_id = ? AND project_id = ?",
                (user_id, project_id),
            ).fetchone()
            is not None
        )
    conn.close()
    if not row:
        return None
    project = _project_row(row, followed=followed, viewer_id=user_id)
    if user_id is None:
        return project
    owner = int(project["ownerUserId"])
    partner = project.get("partnerUserId")
    if user_id not in {owner, partner} and not followed:
        raise PermissionError("forbidden")
    return project


def create_project(user_id: int, data: dict[str, Any], *, publish_to_feed: bool = False) -> dict[str, Any]:
    name = (data.get("name") or data.get("title") or "").strip()
    if not name:
        raise ValueError("name es requerido")
    description = (data.get("description") or "").strip()
    partner = (data.get("partnerName") or data.get("partner_name") or "").strip()
    status = (data.get("status") or "planificacion").strip()
    if status not in {"planificacion", "en_curso", "completado", "pausado"}:
        status = "planificacion"
    requirements = split_requirements(data.get("requirements") or data.get("requisitos"))
    partner_user_id = data.get("partnerUserId") or data.get("partner_user_id")
    partner_user_id = int(partner_user_id) if partner_user_id else None
    delivery_status = _normalize_delivery_status(
        data.get("deliveryStatus") or data.get("delivery_status"),
        "asignado" if partner or partner_user_id else "solicitado",
    )
    events = [_project_event("solicitado", "Proyecto creado", user_id)]
    if partner or partner_user_id:
        events.append(_project_event("asignado", f"Asignado con {partner or f'usuario {partner_user_id}'}", user_id))
        if delivery_status == "en_trabajo":
            events.append(_project_event("en_trabajo", "Trabajo en curso", user_id))
    conn = get_conn()
    project_id = _insert_tracked_project(
        conn,
        user_id=user_id,
        name=name,
        description=description,
        status=status,
        partner_name=partner,
        partner_user_id=partner_user_id,
        delivery_status=delivery_status,
        events=events,
        requirements=requirements,
        category=(data.get("category") or "").strip(),
    )
    conn.commit()
    row = conn.execute("SELECT * FROM projects WHERE id = ?", (project_id,)).fetchone()
    conn.close()
    project = _project_row(row, followed=False, viewer_id=user_id)
    if publish_to_feed:
        profile = get_profile(user_id) or {}
        create_feed_post(
            {
                "user": {
                    "id": user_id,
                    "name": profile.get("name") or data.get("authorName") or "Usuario",
                    "avatar": profile.get("avatar") or "users/user.jpg",
                    "verified": bool(profile.get("verified")),
                    "following": False,
                },
                "description": description or f"Nuevo proyecto: {name}",
                "image_url": data.get("image_url") or "background1.png",
                "cost": 1,
                "cost_type": "proyecto",
                "card_title": name,
                "location": data.get("location") or "",
                "category": data.get("category") or "proyecto",
            }
        )
    return project


def _load_project_row(conn, project_id: int):
    return conn.execute("SELECT * FROM projects WHERE id = ?", (project_id,)).fetchone()


def update_project_delivery(project_id: int, actor_id: int, status: str) -> dict[str, Any]:
    wanted = _normalize_delivery_status(status, "")
    if not wanted:
        raise ValueError("status inválido")
    conn = get_conn()
    row = _load_project_row(conn, project_id)
    if not row:
        conn.close()
        raise KeyError("not_found")
    current = _project_row(row, viewer_id=actor_id)
    owner = int(current["ownerUserId"])
    partner = current.get("partnerUserId")
    participants = {owner} if partner is None else {owner, int(partner)}
    if actor_id not in participants:
        conn.close()
        raise PermissionError("solo los participantes pueden actualizar la entrega")
    current_status = current["deliveryStatus"]
    if wanted == current_status:
        conn.close()
        return current
    if wanted not in ALLOWED_DELIVERY_TRANSITIONS.get(current_status, set()):
        conn.close()
        raise ValueError(f"No se puede pasar de {current_status} a {wanted}")
    if wanted == "confirmado" and actor_id != owner:
        conn.close()
        raise PermissionError("solo quien creó el proyecto puede confirmar la entrega")
    titles = {
        "asignado": "Profesional asignado",
        "en_trabajo": "Trabajo en curso",
        "entregado": "Entrega registrada",
        "confirmado": "Entrega confirmada",
    }
    events = list(current.get("events") or [])
    events.append(_project_event(wanted, titles.get(wanted, wanted), actor_id))
    project_status = STATUS_FROM_DELIVERY.get(wanted, row["status"])
    conn.execute(
        """
        UPDATE projects
        SET delivery_status = ?, status = ?, events_json = ?
        WHERE id = ?
        """,
        (wanted, project_status, json.dumps(events), project_id),
    )
    conn.commit()
    updated = _load_project_row(conn, project_id)
    conn.close()
    return _project_row(updated, viewer_id=actor_id)


def submit_project_delivery(project_id: int, actor_id: int, data: dict[str, Any]) -> dict[str, Any]:
    conn = get_conn()
    row = _load_project_row(conn, project_id)
    if not row:
        conn.close()
        raise KeyError("not_found")
    current = _project_row(row, viewer_id=actor_id)
    owner = int(current["ownerUserId"])
    partner = current.get("partnerUserId")
    participants = {owner} if partner is None else {owner, int(partner)}
    if actor_id not in participants:
        conn.close()
        raise PermissionError("solo los participantes pueden entregar")
    if current["deliveryStatus"] not in {"en_trabajo", "asignado"}:
        conn.close()
        raise ValueError("el proyecto aún no está listo para entregar")
    profile = get_profile(actor_id) or {}
    delivery = {
        "message": (data.get("message") or "Entrega del proyecto").strip(),
        "image": data.get("image") or data.get("image_url") or "background4.png",
        "submittedAt": _utc_now_iso(),
        "submittedBy": actor_id,
        "providerName": profile.get("name") or f"Usuario {actor_id}",
        "providerAvatar": profile.get("avatar") or "users/user.jpg",
    }
    events = list(current.get("events") or [])
    if current["deliveryStatus"] == "asignado":
        events.append(_project_event("en_trabajo", "Trabajo en curso", actor_id))
    events.append(_project_event("entregado", delivery["message"], actor_id))
    conn.execute(
        """
        UPDATE projects
        SET delivery_status = 'entregado', status = 'en_curso',
            delivery_json = ?, events_json = ?
        WHERE id = ?
        """,
        (json.dumps(delivery), json.dumps(events), project_id),
    )
    conn.commit()
    updated = _load_project_row(conn, project_id)
    conn.close()
    return _project_row(updated, viewer_id=actor_id)


def list_following_ids(user_id: int) -> list[int]:
    conn = get_conn()
    rows = conn.execute(
        "SELECT followed_id FROM user_follows WHERE follower_id = ?",
        (user_id,),
    ).fetchall()
    conn.close()
    return [int(r["followed_id"]) for r in rows]


def toggle_follow_user(follower_id: int, followed_id: int) -> dict[str, Any]:
    if int(follower_id) == int(followed_id):
        raise ValueError("No puedes seguirte a ti mismo")
    conn = get_conn()
    row = conn.execute(
        "SELECT 1 FROM user_follows WHERE follower_id = ? AND followed_id = ?",
        (follower_id, followed_id),
    ).fetchone()
    if row:
        conn.execute(
            "DELETE FROM user_follows WHERE follower_id = ? AND followed_id = ?",
            (follower_id, followed_id),
        )
        following = False
    else:
        conn.execute(
            "INSERT INTO user_follows (follower_id, followed_id, created_at) VALUES (?, ?, ?)",
            (follower_id, followed_id, _utc_now_iso()),
        )
        following = True
    conn.commit()
    conn.close()
    return {"following": following, "followedId": followed_id}


def toggle_follow_project(user_id: int, project_id: int) -> dict[str, Any]:
    conn = get_conn()
    project = conn.execute("SELECT * FROM projects WHERE id = ?", (project_id,)).fetchone()
    if not project:
        conn.close()
        raise KeyError("not_found")
    row = conn.execute(
        "SELECT 1 FROM project_follows WHERE user_id = ? AND project_id = ?",
        (user_id, project_id),
    ).fetchone()
    if row:
        conn.execute(
            "DELETE FROM project_follows WHERE user_id = ? AND project_id = ?",
            (user_id, project_id),
        )
        followed = False
    else:
        conn.execute(
            "INSERT INTO project_follows (user_id, project_id, created_at) VALUES (?, ?, ?)",
            (user_id, project_id, _utc_now_iso()),
        )
        followed = True
    conn.commit()
    conn.close()
    return {"followed": followed, "projectId": project_id}


def create_story(user_id: int, data: dict[str, Any]) -> dict[str, Any]:
    profile = get_profile(user_id) or {}
    user = {
        "id": user_id,
        "name": profile.get("name") or data.get("authorName") or "Usuario",
        "avatar": profile.get("avatar") or "users/user.jpg",
        "verified": bool(profile.get("verified")),
        "following": False,
    }
    caption = (data.get("caption") or "").strip()
    if not caption:
        raise ValueError("caption es requerido")
    conn = get_conn()
    cur = conn.cursor()
    cur.execute(
        """
        INSERT INTO stories (user_json, caption, image_url, card_id, card_title, timestamp, duration, viewed)
        VALUES (?, ?, ?, ?, ?, ?, ?, 0)
        """,
        (
            json.dumps(user),
            caption,
            data.get("image_url") or "background1.png",
            data.get("card_id") or data.get("cardId") or 0,
            data.get("card_title") or data.get("cardTitle") or "",
            _utc_now_iso(),
            int(data.get("duration") or 5),
        ),
    )
    conn.commit()
    row = conn.execute("SELECT * FROM stories WHERE id = ?", (cur.lastrowid,)).fetchone()
    conn.close()
    return _story_row(row)


def get_story(story_id: int) -> dict[str, Any] | None:
    conn = get_conn()
    row = conn.execute("SELECT * FROM stories WHERE id = ?", (story_id,)).fetchone()
    conn.close()
    return _story_row(row) if row else None


def _ensure_demo_profiles(conn: sqlite3.Connection) -> None:
    """Perfil Tina Shah (Figma) y datos sociales de demo."""
    tina = conn.execute("SELECT 1 FROM profiles WHERE user_id = 2").fetchone()
    if not tina:
        profile = {
            "id": 2,
            "name": "Tina Shah",
            "verified": True,
            "avatar": "users/4.jpg",
            "contacts": 24,
            "professions": ["Pintor", "Carpintero", "Escultor"],
            "localContacts": 16,
            "remoteContacts": 8,
            "localAvailable": True,
            "remoteAvailable": True,
            "skills": [
                {"id": 1, "name": "Pintura al óleo"},
                {"id": 2, "name": "Escultura"},
                {"id": 3, "name": "Carpintero"},
            ],
            "portfolio": [
                {"id": i + 1, "title": f"Trabajo {i + 1}", "description": "", "image": img}
                for i, img in enumerate(
                    [
                        "background1.png",
                        "background2.png",
                        "background3.png",
                        "background4.png",
                        "background5.png",
                        "background2.png",
                    ]
                )
            ],
            "reviews": [
                {
                    "id": 1,
                    "user": {"id": 10, "name": "Nathan", "avatar": "users/2.jpg", "verified": False, "following": False},
                    "rating": 5,
                    "date": "2024-12-01",
                    "serviceTitle": "Mesa de madera",
                    "text": "Excelente trabajo.",
                },
                {
                    "id": 2,
                    "user": {"id": 11, "name": "María L.", "avatar": "users/3.jpg", "verified": True, "following": False},
                    "rating": 5,
                    "date": "2024-11-20",
                    "serviceTitle": "Pintura al óleo",
                    "text": "Impecable. Cumplió plazos y presupuesto.",
                },
            ],
        }
        conn.execute(
            "INSERT INTO profiles (user_id, data_json) VALUES (?, ?)",
            (2, json.dumps(profile)),
        )

    if conn.execute("SELECT COUNT(*) AS c FROM notifications").fetchone()["c"] == 0:
        notifs = [
            (
                1,
                json.dumps({"name": "Darrell Trivedi", "avatar": "users/2.jpg"}),
                "Darrell Trivedi has a new story up. What's your reaction?",
                "2 hours ago",
                1,
            ),
            (
                1,
                json.dumps({"name": "Laura M.", "avatar": "users/1.jpg"}),
                "Laura M. aceptó tu solicitud de intercambio de favores.",
                "3 hours ago",
                1,
            ),
            (
                1,
                json.dumps({"name": "Diego R.", "avatar": "users/2.jpg"}),
                "Diego R. comentó en tu publicación de paseo de mascotas.",
                "5 hours ago",
                1,
            ),
            (
                1,
                json.dumps({"name": "Sofía K.", "avatar": "users/3.jpg"}),
                "Sofía K. te envió un mensaje sobre clases de guitarra.",
                "1 day ago",
                0,
            ),
            (
                1,
                json.dumps({"name": "Beth Williams", "avatar": "users/4.jpg"}),
                "Beth Williams publicó un nuevo favor en carpintería.",
                "2 days ago",
                0,
            ),
        ]
        for n in notifs:
            conn.execute(
                """
                INSERT INTO notifications (user_id, from_user_json, message, time_ago, is_recent, created_at)
                VALUES (?, ?, ?, ?, ?, ?)
                """,
                (*n, _utc_now_iso()),
            )

    if conn.execute("SELECT COUNT(*) AS c FROM message_threads").fetchone()["c"] == 0:
        threads = [
            (
                1,
                json.dumps({"id": 1, "name": "Laura M.", "avatar": "users/1.jpg"}),
                "¿Te parece el intercambio de inglés por paseos?",
                "10:30",
                2,
            ),
            (
                1,
                json.dumps({"id": 2, "name": "Diego R.", "avatar": "users/2.jpg"}),
                "Perfecto, nos vemos el sábado.",
                "Ayer",
                0,
            ),
            (
                1,
                json.dumps({"id": 3, "name": "Sofía K.", "avatar": "users/3.jpg"}),
                "Te envié fotos de mis trabajos de pintura.",
                "Lun",
                1,
            ),
        ]
        for t in threads:
            conn.execute(
                """
                INSERT INTO message_threads (user_id, peer_json, last_message, time_label, unread, created_at)
                VALUES (?, ?, ?, ?, ?, ?)
                """,
                (*t, _utc_now_iso()),
            )


def _next_tracking(prefix: str = "AW") -> str:
    conn = get_conn()
    count = conn.execute("SELECT COUNT(*) AS c FROM quotes").fetchone()["c"]
    conn.close()
    year = datetime.now(timezone.utc).year
    return f"{prefix}-{year}-{count + 1:03d}"


def create_quote(data: dict[str, Any]) -> dict[str, Any]:
    tracking = data.get("tracking_number") or _next_tracking()
    client_id = data.get("client_id")
    pay_with = data.get("pay_with")
    cost = int(data.get("coin_cost", 5))
    if client_id and pay_with in ("red", "blue"):
        ok = deduct_coins(int(client_id), pay_with, cost)
        if not ok:
            return {}
    services = data.get("services", [])
    materials = data.get("materials", [])
    provider_id = int(data["provider_id"])
    provider = get_profile(provider_id) or {}
    provider_name = data.get("provider_name") or provider.get("name", "Proveedor")
    provider_avatar = provider.get("avatar", "users/user.jpg")
    title = services[0] if services else "Servicio"
    line_items = [{"label": s, "amount": 2000} for s in services]
    line_items += [{"label": m, "amount": 2000} for m in materials]
    shipping = 500
    line_items.append({"label": "Envío", "amount": shipping})
    total_al = sum(i["amount"] for i in line_items)
    now = datetime.now(timezone.utc)
    ts_label = now.strftime("%B %d, %H:%M")
    activities = [
        {
            "type": "order_placed",
            "title": "Hiciste el pedido",
            "timestamp": ts_label,
            "icon": "green",
        },
        {
            "type": "requirements_sent",
            "title": "Enviaste los requisitos",
            "timestamp": ts_label,
            "icon": "pink",
            "linkLabel": "ver requisitos",
            "linkTab": "requisitos",
        },
    ]
    requirements = data.get("requirements") or [
        {"question": "Industria", "answer": "Tecnología"},
        {"question": "¿Tienes un objetivo definido?", "answer": f"Sí, {title.lower()}"},
        {
            "question": "Materiales o especificaciones",
            "answer": ", ".join(materials) if materials else "Sin especificaciones adicionales",
        },
    ]
    conn = get_conn()
    cur = conn.cursor()
    cur.execute(
        """
        INSERT INTO quotes (
            provider_id, client_id, tracking_number, services_json, materials_json,
            quote_date, time_slot, status, created_at, title, provider_name, provider_avatar,
            line_items_json, requirements_json, activities_json, total_al, shipping_cost,
            order_start_date, delivery_date
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, 'pendiente', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            provider_id,
            data.get("client_id"),
            tracking,
            json.dumps(services),
            json.dumps(materials),
            data["quote_date"],
            data["time_slot"],
            _utc_now_iso(),
            title,
            provider_name,
            provider_avatar,
            json.dumps(line_items),
            json.dumps(requirements),
            json.dumps(activities),
            total_al,
            shipping,
            data["quote_date"],
            data.get("delivery_date"),
        ),
    )
    conn.commit()
    row = conn.execute("SELECT * FROM quotes WHERE id = ?", (cur.lastrowid,)).fetchone()
    conn.close()
    return _quote_row(row)


def _quote_row(row: sqlite3.Row, viewer_id: int | None = None) -> dict[str, Any]:
    delivery = _parse_json(row["delivery_json"]) if row["delivery_json"] else None
    client_review = _parse_json(row["client_review_json"]) if row["client_review_json"] else None
    provider_review = _parse_json(row["provider_review_json"]) if row["provider_review_json"] else None
    provider_id = row["provider_id"]
    client_id = row["client_id"]
    is_provider = viewer_id is not None and viewer_id == provider_id
    is_client = viewer_id is not None and client_id is not None and viewer_id == client_id
    return {
        "id": row["id"],
        "providerId": provider_id,
        "clientId": client_id,
        "trackingNumber": row["tracking_number"],
        "title": row["title"] or (_parse_json(row["services_json"])[0] if row["services_json"] else "Servicio"),
        "providerName": row["provider_name"] or "Proveedor",
        "providerAvatar": row["provider_avatar"] or "users/user.jpg",
        "services": _parse_json(row["services_json"]),
        "materials": _parse_json(row["materials_json"]),
        "lineItems": _parse_json(row["line_items_json"] or "[]"),
        "requirements": _parse_json(row["requirements_json"] or "[]"),
        "activities": _parse_json(row["activities_json"] or "[]"),
        "delivery": delivery,
        "clientReview": client_review,
        "providerReview": provider_review,
        "totalAl": row["total_al"] or 0,
        "shippingCost": row["shipping_cost"] or 0,
        "date": row["quote_date"],
        "deliveryDate": row["delivery_date"],
        "orderStartDate": row["order_start_date"],
        "timeSlot": row["time_slot"],
        "status": row["status"],
        "createdAt": row["created_at"],
        "isProvider": is_provider,
        "isClient": is_client,
    }


def create_report(data: dict[str, Any]) -> dict[str, Any]:
    conn = get_conn()
    cur = conn.cursor()
    cur.execute(
        """
        INSERT INTO reports (user_id, provider_id, tracking_number, action, created_at)
        VALUES (?, ?, ?, ?, ?)
        """,
        (
            data.get("user_id"),
            data.get("provider_id"),
            data["tracking_number"],
            data["action"],
            _utc_now_iso(),
        ),
    )
    conn.commit()
    row = conn.execute("SELECT * FROM reports WHERE id = ?", (cur.lastrowid,)).fetchone()
    conn.close()
    return {
        "id": row["id"],
        "trackingNumber": row["tracking_number"],
        "action": row["action"],
        "message": "Tu reporte ha sido creado",
    }


def add_profile_review(provider_id: int, data: dict[str, Any]) -> dict[str, Any]:
    prof = get_profile(provider_id)
    if not prof:
        return {}
    reviews = prof.get("reviews", [])
    new_id = max((r.get("id", 0) for r in reviews), default=0) + 1
    review = {
        "id": new_id,
        "user": data.get("user") or {"id": 0, "name": "Usuario", "avatar": "users/user.jpg", "verified": False, "following": False},
        "rating": int(data.get("rating", 5)),
        "date": datetime.utcnow().strftime("%Y-%m-%d"),
        "serviceTitle": data.get("service_title") or data.get("serviceTitle") or "",
        "text": data["text"],
    }
    reviews.append(review)
    prof["reviews"] = reviews
    conn = get_conn()
    conn.execute(
        "UPDATE profiles SET data_json = ? WHERE user_id = ?",
        (json.dumps(prof), provider_id),
    )
    conn.commit()
    conn.close()
    return review


def list_notifications(user_id: int) -> list[dict[str, Any]]:
    conn = get_conn()
    rows = conn.execute(
        "SELECT * FROM notifications WHERE user_id = ? ORDER BY id DESC",
        (user_id,),
    ).fetchall()
    if not rows:
        rows = conn.execute(
            "SELECT * FROM notifications WHERE user_id = 1 ORDER BY id DESC",
        ).fetchall()
    conn.close()
    return [_notification_row(r) for r in rows]


def _notification_row(row: sqlite3.Row) -> dict[str, Any]:
    from_user = _parse_json(row["from_user_json"]) if row["from_user_json"] else {}
    return {
        "id": row["id"],
        "userName": from_user.get("name", ""),
        "avatarKey": from_user.get("avatar", "users/user.jpg"),
        "message": row["message"],
        "timeAgo": row["time_ago"],
        "isRecent": bool(row["is_recent"]),
    }


def delete_notification(user_id: int, notif_id: int) -> bool:
    conn = get_conn()
    cur = conn.execute(
        "DELETE FROM notifications WHERE id = ? AND user_id = ?",
        (notif_id, user_id),
    )
    conn.commit()
    ok = cur.rowcount > 0
    conn.close()
    return ok


def list_message_threads(user_id: int) -> list[dict[str, Any]]:
    conn = get_conn()
    rows = conn.execute(
        "SELECT * FROM message_threads WHERE user_id = ? ORDER BY id DESC",
        (user_id,),
    ).fetchall()
    if not rows:
        rows = conn.execute(
            "SELECT * FROM message_threads WHERE user_id = 1 ORDER BY id DESC",
        ).fetchall()
    conn.close()
    return [_message_row(r) for r in rows]


def _message_row(row: sqlite3.Row) -> dict[str, Any]:
    peer = _parse_json(row["peer_json"])
    return {
        "id": row["id"],
        "name": peer.get("name", ""),
        "avatarKey": peer.get("avatar", "users/user.jpg"),
        "profession": peer.get("profession", ""),
        "peerId": peer.get("id"),
        "lastMessage": row["last_message"],
        "time": row["time_label"],
        "unread": row["unread"],
    }


def unread_message_count(user_id: int) -> int:
    conn = get_conn()
    row = conn.execute(
        "SELECT COALESCE(SUM(unread), 0) AS c FROM message_threads WHERE user_id = ?",
        (user_id,),
    ).fetchone()
    conn.close()
    return int(row["c"])


def get_wallet(user_id: int) -> dict[str, int]:
    prof = get_profile(user_id) or ensure_profile(user_id)
    return {
        "redCoins": int(prof.get("redCoins", 2)),
        "blueCoins": int(prof.get("blueCoins", 1)),
        "quoteCost": int(prof.get("quoteCost", 5)),
    }


def deduct_coins(user_id: int, coin_type: str, amount: int) -> bool:
    prof = get_profile(user_id)
    if not prof:
        return False
    key = "redCoins" if coin_type == "red" else "blueCoins"
    balance = int(prof.get(key, 0))
    if balance < amount:
        return False
    prof[key] = balance - amount
    _save_profile(user_id, prof)
    return True


def purchase_blue_coins(user_id: int, amount: int | None = None, amount_mxn: int | None = None) -> dict[str, Any]:
    prof = get_profile(user_id) or ensure_profile(user_id)
    if amount_mxn is not None:
        coins = int(amount_mxn * 0.9)
    else:
        coins = int(amount or 10)
    prof["blueCoins"] = int(prof.get("blueCoins", 0)) + coins
    _save_profile(user_id, prof)
    wallet = get_wallet(user_id)
    return {
        **wallet,
        "coinsAdded": coins,
        "amountMxn": amount_mxn if amount_mxn is not None else 0,
    }


def _seed_demo_order(conn: sqlite3.Connection) -> None:
    if conn.execute("SELECT 1 FROM quotes WHERE tracking_number = ?", ("1020405060",)).fetchone():
        return
    activities = [
        {"type": "order_placed", "title": "Hiciste el pedido", "timestamp": "28 marzo, 15:20", "icon": "green"},
        {
            "type": "requirements_sent",
            "title": "Enviaste los requisitos",
            "timestamp": "28 marzo, 15:30",
            "icon": "pink",
            "linkLabel": "ver requisitos",
            "linkTab": "requisitos",
        },
        {"type": "started", "title": "Tu pedido comenzó", "timestamp": "28 marzo, 15:30", "icon": "yellow"},
        {"type": "delivery_updated", "title": "Su fecha de entrega se actualizó", "timestamp": "28 marzo, 15:30", "icon": "blue"},
        {
            "type": "delivered",
            "title": "Big Mike entregó su pedido",
            "timestamp": "1 abril, 13:10",
            "icon": "avatar",
            "avatar": "users/2.jpg",
        },
        {
            "type": "client_review",
            "title": "Dejaste una reseña",
            "timestamp": "1 abril, 13:10",
            "icon": "avatar",
            "avatar": "users/user.jpg",
            "rating": 5.0,
            "text": "Excelente servicio! Cumplió con lo solicitado y es muy atento.",
        },
        {
            "type": "provider_review",
            "title": "Big Mike dejó una reseña",
            "timestamp": "1 abril, 13:10",
            "icon": "avatar",
            "avatar": "users/2.jpg",
            "rating": 5.0,
            "text": "Gracias! Fue un placer trabajar contigo.",
        },
    ]
    requirements = [
        {"question": "Industria", "answer": "Tecnología"},
        {"question": "¿Tienes un objetivo definido?", "answer": "Sí, una mesa"},
        {"question": "Materiales o especificaciones", "answer": "Quiero una mesa de mármol, 2x2 para 4 personas"},
    ]
    line_items = [
        {"label": "Mesa de 2x4", "amount": 2000},
        {"label": "Mármol", "amount": 2000},
        {"label": "Envío", "amount": 500},
    ]
    delivery = {
        "number": 1,
        "message": (
            "¡Hola! Aquí está tu mesa :) , espero te guste! Envío tu pedido llegará en días :), "
            "déjame saber qué piensas :)"
        ),
        "image": "background4.png",
        "providerName": "Big Mike",
        "providerAvatar": "users/2.jpg",
    }
    conn.execute(
        """
        INSERT INTO quotes (
            provider_id, client_id, tracking_number, services_json, materials_json,
            quote_date, time_slot, status, created_at, title, provider_name, provider_avatar,
            line_items_json, requirements_json, activities_json, delivery_json, total_al,
            shipping_cost, order_start_date, delivery_date, client_review_json, provider_review_json
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            5,
            1,
            "1020405060",
            json.dumps(["Mesa de 2x4"]),
            json.dumps(["Mármol"]),
            "2025-03-28",
            "15:30",
            "entregado",
            _utc_now_iso(),
            "Mesa de madera",
            "Big Mike",
            "users/2.jpg",
            json.dumps(line_items),
            json.dumps(requirements),
            json.dumps(activities),
            json.dumps(delivery),
            4500,
            500,
            "2025-03-28",
            "2025-04-01",
            json.dumps({"rating": 5.0, "text": "Excelente servicio! Cumplió con lo solicitado y es muy atento."}),
            json.dumps({"rating": 5.0, "text": "Gracias! Fue un placer trabajar contigo."}),
        ),
    )


def list_orders(user_id: int) -> list[dict[str, Any]]:
    conn = get_conn()
    rows = conn.execute(
        """
        SELECT * FROM quotes
        WHERE client_id = ? OR provider_id = ?
        ORDER BY created_at DESC
        """,
        (user_id, user_id),
    ).fetchall()
    conn.close()
    return [_quote_row(r, user_id) for r in rows]


def get_order(tracking: str, user_id: int | None = None) -> dict[str, Any] | None:
    conn = get_conn()
    row = conn.execute("SELECT * FROM quotes WHERE tracking_number = ?", (tracking,)).fetchone()
    conn.close()
    if not row:
        return None
    return _quote_row(row, user_id)


def submit_order_delivery(tracking: str, user_id: int, data: dict[str, Any]) -> dict[str, Any] | None:
    conn = get_conn()
    row = conn.execute("SELECT * FROM quotes WHERE tracking_number = ?", (tracking,)).fetchone()
    if not row or row["provider_id"] != user_id:
        conn.close()
        return None
    provider = get_profile(user_id) or {}
    delivery = {
        "number": 1,
        "message": data.get("message", ""),
        "image": data.get("image", "background4.png"),
        "providerName": provider.get("name", row["provider_name"] or "Proveedor"),
        "providerAvatar": provider.get("avatar", "users/user.jpg"),
    }
    activities = _parse_json(row["activities_json"] or "[]")
    now = datetime.now(timezone.utc).strftime("%d %B, %H:%M")
    activities.append(
        {
            "type": "delivered",
            "title": f"{delivery['providerName']} entregó su pedido",
            "timestamp": now,
            "icon": "avatar",
            "avatar": delivery["providerAvatar"],
        }
    )
    conn.execute(
        """
        UPDATE quotes
        SET delivery_json = ?, activities_json = ?, status = 'entregado', delivery_date = ?
        WHERE tracking_number = ?
        """,
        (json.dumps(delivery), json.dumps(activities), datetime.now(timezone.utc).strftime("%Y-%m-%d"), tracking),
    )
    conn.commit()
    updated = conn.execute("SELECT * FROM quotes WHERE tracking_number = ?", (tracking,)).fetchone()
    conn.close()
    return _quote_row(updated, user_id)


def _seed_social_extras(conn: sqlite3.Connection) -> None:
    james = conn.execute(
        "SELECT id FROM message_threads WHERE user_id = 1 AND peer_json LIKE '%James%'"
    ).fetchone()
    if not james:
        cur = conn.cursor()
        cur.execute(
            """
            INSERT INTO message_threads (user_id, peer_json, last_message, time_label, unread, created_at)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (
                1,
                json.dumps({"id": 10, "name": "James", "avatar": "users/2.jpg", "profession": "Arquitecto"}),
                "María te quiere contactar para realizar una mesa de madera",
                "9:41",
                2,
                _utc_now_iso(),
            ),
        )
        james_id = cur.lastrowid
        cur.execute(
            """
            INSERT INTO message_threads (user_id, peer_json, last_message, time_label, unread, created_at)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (
                1,
                json.dumps({"id": 11, "name": "Will Kenny", "avatar": "users/3.jpg", "profession": "Veterinario"}),
                "¿Podemos agendar la consulta?",
                "Ayer",
                0,
                _utc_now_iso(),
            ),
        )
        conn.commit()
    else:
        james_id = james["id"]

    if conn.execute("SELECT COUNT(*) AS c FROM chat_messages WHERE thread_id = ?", (james_id,)).fetchone()["c"] == 0:
        msgs = [
            ("system", "contact_request", "María te quiere contactar para realizar una mesa de madera", None),
            ("peer", "text", "¡Hola! Claro, puedo ayudarte con la mesa. ¿Qué medidas necesitas?", None),
            ("me", "text", "2x2 para 4 personas, de mármol si es posible.", None),
            ("peer", "text", "Perfecto. Te preparo una cotización.", None),
            ("peer", "quote", "2800", json.dumps({"currency": "MX", "amount": 2800})),
        ]
        for sender, mtype, body, meta in msgs:
            conn.execute(
                """
                INSERT INTO chat_messages (thread_id, sender, message_type, body, meta_json, created_at)
                VALUES (?, ?, ?, ?, ?, ?)
                """,
                (james_id, sender, mtype, body, meta, _utc_now_iso()),
            )

    if conn.execute("SELECT COUNT(*) AS c FROM projects WHERE user_id = 1").fetchone()["c"] < 3:
        extra_projects = [
            ("Reparación de jardín", "Intercambio de jardinería por clases de cocina", "completado", "Carlos R."),
            ("Diseño de logo", "Logo para emprendimiento local", "planificacion", "Ana P."),
        ]
        for name, desc, status, partner in extra_projects:
            exists = conn.execute(
                "SELECT 1 FROM projects WHERE user_id = 1 AND name = ?",
                (name,),
            ).fetchone()
            if not exists:
                conn.execute(
                    """
                    INSERT INTO projects (user_id, name, description, status, partner_name)
                    VALUES (1, ?, ?, ?, ?)
                    """,
                    (name, desc, status, partner),
                )

    if conn.execute("SELECT COUNT(*) AS c FROM contact_requests WHERE user_id = 1 AND status = 'accepted'").fetchone()["c"] == 0:
        conn.execute(
            """
            INSERT INTO contact_requests (user_id, requester_json, subtitle, status, created_at)
            VALUES (?, ?, ?, 'accepted', ?)
            """,
            (
                1,
                json.dumps({"id": 25, "name": "Tina Shah", "avatar": "users/4.jpg"}),
                "Pintor, Carpintero",
                _utc_now_iso(),
            ),
        )

    if conn.execute("SELECT COUNT(*) AS c FROM contact_requests WHERE user_id = 1").fetchone()["c"] == 0:
        requests = [
            (1, json.dumps({"id": 20, "name": "Fred Oberbrunner", "avatar": "users/1.jpg"}), "Arquitecto"),
            (1, json.dumps({"id": 21, "name": "Catherine H.", "avatar": "users/3.jpg"}), ""),
            (1, json.dumps({"id": 22, "name": "Providencia Alten", "avatar": "users/4.jpg"}), "Senior usability geek"),
            (1, json.dumps({"id": 23, "name": "Emma Konopelski", "avatar": "users/2.jpg"}), ""),
        ]
        for uid, peer, subtitle in requests:
            conn.execute(
                """
                INSERT INTO contact_requests (user_id, requester_json, subtitle, status, created_at)
                VALUES (?, ?, ?, 'pending', ?)
                """,
                (uid, peer, subtitle, _utc_now_iso()),
            )

    if conn.execute("SELECT COUNT(*) AS c FROM blocked_contacts WHERE user_id = 1").fetchone()["c"] == 0:
        conn.execute(
            """
            INSERT INTO blocked_contacts (user_id, blocked_json, created_at)
            VALUES (?, ?, ?)
            """,
            (1, json.dumps({"id": 30, "name": "James", "avatar": "users/2.jpg"}), _utc_now_iso()),
        )


def list_contacts(user_id: int) -> list[dict[str, Any]]:
    """Contactos aceptados: hilos de chat + solicitudes aceptadas."""
    contacts: list[dict[str, Any]] = []
    seen_peers: set[int] = set()
    for thread in list_message_threads(user_id):
        peer_id = thread.get("peerId")
        if peer_id is not None:
            if peer_id in seen_peers:
                continue
            seen_peers.add(peer_id)
        contacts.append(
            {
                "id": thread["id"],
                "threadId": thread["id"],
                "peerId": peer_id,
                "name": thread["name"],
                "avatarKey": thread["avatarKey"],
                "profession": thread.get("profession", ""),
                "lastMessage": thread.get("lastMessage", ""),
                "time": thread.get("time", ""),
                "source": "chat",
            }
        )
    conn = get_conn()
    rows = conn.execute(
        """
        SELECT * FROM contact_requests
        WHERE user_id = ? AND status = 'accepted'
        ORDER BY id DESC
        """,
        (user_id,),
    ).fetchall()
    if not rows:
        rows = conn.execute(
            "SELECT * FROM contact_requests WHERE user_id = 1 AND status = 'accepted' ORDER BY id DESC",
        ).fetchall()
    conn.close()
    for row in rows:
        peer = _parse_json(row["requester_json"])
        peer_id = peer.get("id")
        if peer_id is not None and peer_id in seen_peers:
            continue
        if peer_id is not None:
            seen_peers.add(peer_id)
        contacts.append(
            {
                "id": row["id"],
                "threadId": None,
                "peerId": peer_id,
                "name": peer.get("name", ""),
                "avatarKey": peer.get("avatar", "users/user.jpg"),
                "profession": row["subtitle"] or "",
                "lastMessage": "",
                "time": "",
                "source": "accepted",
            }
        )
    return contacts


def list_contact_requests(user_id: int) -> list[dict[str, Any]]:
    conn = get_conn()
    rows = conn.execute(
        "SELECT * FROM contact_requests WHERE user_id = ? AND status = 'pending' ORDER BY id DESC",
        (user_id,),
    ).fetchall()
    if not rows:
        rows = conn.execute(
            "SELECT * FROM contact_requests WHERE user_id = 1 AND status = 'pending' ORDER BY id DESC",
        ).fetchall()
    conn.close()
    return [_contact_request_row(r) for r in rows]


def _contact_request_row(row: sqlite3.Row) -> dict[str, Any]:
    peer = _parse_json(row["requester_json"])
    return {
        "id": row["id"],
        "name": peer.get("name", ""),
        "avatarKey": peer.get("avatar", "users/user.jpg"),
        "subtitle": row["subtitle"] or "",
        "status": row["status"],
    }


def respond_contact_request(request_id: int, user_id: int, accept: bool) -> dict[str, Any] | None:
    conn = get_conn()
    row = conn.execute("SELECT * FROM contact_requests WHERE id = ?", (request_id,)).fetchone()
    if not row:
        conn.close()
        return None
    status = "accepted" if accept else "rejected"
    conn.execute(
        "UPDATE contact_requests SET status = ? WHERE id = ?",
        (status, request_id),
    )
    conn.commit()
    updated = conn.execute("SELECT * FROM contact_requests WHERE id = ?", (request_id,)).fetchone()
    conn.close()
    return _contact_request_row(updated)


def _pending_contact_from_user(to_user_id: int, from_user_id: int) -> bool:
    conn = get_conn()
    rows = conn.execute(
        "SELECT requester_json FROM contact_requests WHERE user_id = ? AND status = 'pending'",
        (to_user_id,),
    ).fetchall()
    conn.close()
    for row in rows:
        peer = _parse_json(row["requester_json"])
        if peer.get("id") == from_user_id:
            return True
    return False


def create_contact_request(from_user_id: int, to_user_id: int, subtitle: str = "") -> dict[str, Any] | None:
    if from_user_id == to_user_id:
        return None
    if _pending_contact_from_user(to_user_id, from_user_id):
        return None
    prof = get_profile(from_user_id) or ensure_profile(from_user_id)
    requester = {
        "id": from_user_id,
        "name": prof.get("name", "Usuario"),
        "avatar": prof.get("avatar", "users/user.jpg"),
    }
    conn = get_conn()
    cur = conn.cursor()
    cur.execute(
        """
        INSERT INTO contact_requests (user_id, requester_json, subtitle, status, created_at)
        VALUES (?, ?, ?, 'pending', ?)
        """,
        (to_user_id, json.dumps(requester), subtitle or "Quiere agregarte como contacto", _utc_now_iso()),
    )
    conn.commit()
    row = conn.execute("SELECT * FROM contact_requests WHERE id = ?", (cur.lastrowid,)).fetchone()
    conn.close()
    return _contact_request_row(row)


def get_or_create_message_thread(
    user_id: int,
    peer_id: int,
    peer_name: str = "",
    peer_avatar: str = "users/user.jpg",
    peer_profession: str = "",
) -> dict[str, Any]:
    for thread in list_message_threads(user_id):
        if thread.get("peerId") == peer_id:
            return thread
    conn = get_conn()
    cur = conn.cursor()
    peer = {
        "id": peer_id,
        "name": peer_name or f"Usuario {peer_id}",
        "avatar": peer_avatar,
        "profession": peer_profession,
    }
    cur.execute(
        """
        INSERT INTO message_threads (user_id, peer_json, last_message, time_label, unread, created_at)
        VALUES (?, ?, ?, ?, ?, ?)
        """,
        (user_id, json.dumps(peer), "Nueva conversación", "Ahora", 0, _utc_now_iso()),
    )
    conn.commit()
    row = conn.execute("SELECT * FROM message_threads WHERE id = ?", (cur.lastrowid,)).fetchone()
    conn.close()
    return _message_row(row)


def list_blocked_contacts(user_id: int) -> list[dict[str, Any]]:
    conn = get_conn()
    rows = conn.execute(
        "SELECT * FROM blocked_contacts WHERE user_id = ? ORDER BY id DESC",
        (user_id,),
    ).fetchall()
    if not rows:
        rows = conn.execute(
            "SELECT * FROM blocked_contacts WHERE user_id = 1 ORDER BY id DESC",
        ).fetchall()
    conn.close()
    return [_blocked_row(r) for r in rows]


def _blocked_row(row: sqlite3.Row) -> dict[str, Any]:
    peer = _parse_json(row["blocked_json"])
    return {
        "id": row["id"],
        "name": peer.get("name", ""),
        "avatarKey": peer.get("avatar", "users/user.jpg"),
        "peerId": peer.get("id"),
    }


def unblock_contact(block_id: int, user_id: int) -> bool:
    conn = get_conn()
    cur = conn.execute("DELETE FROM blocked_contacts WHERE id = ? AND user_id = ?", (block_id, user_id))
    if cur.rowcount == 0:
        cur = conn.execute("DELETE FROM blocked_contacts WHERE id = ?", (block_id,))
    conn.commit()
    ok = cur.rowcount > 0
    conn.close()
    return ok


def get_thread_messages(thread_id: int) -> list[dict[str, Any]]:
    conn = get_conn()
    rows = conn.execute(
        "SELECT * FROM chat_messages WHERE thread_id = ? ORDER BY id ASC",
        (thread_id,),
    ).fetchall()
    conn.close()
    return [_chat_message_row(r) for r in rows]


def _chat_message_row(row: sqlite3.Row) -> dict[str, Any]:
    meta = _parse_json(row["meta_json"]) if row["meta_json"] else None
    return {
        "id": row["id"],
        "sender": row["sender"],
        "type": row["message_type"],
        "body": row["body"],
        "meta": meta,
    }


def get_message_thread(thread_id: int) -> dict[str, Any] | None:
    conn = get_conn()
    row = conn.execute("SELECT * FROM message_threads WHERE id = ?", (thread_id,)).fetchone()
    conn.close()
    if not row:
        return None
    return _message_row(row)


def add_chat_message(thread_id: int, sender: str, message_type: str, body: str, meta: dict | None = None) -> dict[str, Any]:
    conn = get_conn()
    cur = conn.cursor()
    cur.execute(
        """
        INSERT INTO chat_messages (thread_id, sender, message_type, body, meta_json, created_at)
        VALUES (?, ?, ?, ?, ?, ?)
        """,
        (thread_id, sender, message_type, body, json.dumps(meta) if meta else None, _utc_now_iso()),
    )
    conn.execute(
        "UPDATE message_threads SET last_message = ?, time_label = ? WHERE id = ?",
        (body if message_type == "text" else body, "Ahora", thread_id),
    )
    conn.commit()
    row = conn.execute("SELECT * FROM chat_messages WHERE id = ?", (cur.lastrowid,)).fetchone()
    conn.close()
    return _chat_message_row(row)


def _ensure_identity_table(conn) -> None:
    if is_postgres():
        return
    conn.executescript(
        """
        CREATE TABLE IF NOT EXISTS identity_verifications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            status TEXT NOT NULL DEFAULT 'pending',
            curp TEXT,
            face_distance REAL,
            face_match INTEGER NOT NULL DEFAULT 0,
            result_json TEXT NOT NULL,
            created_at TEXT NOT NULL
        );
        """
    )


def get_identity_status(user_id: int) -> dict[str, Any]:
    conn = get_conn()
    row = conn.execute(
        """
        SELECT * FROM identity_verifications
        WHERE user_id = ?
        ORDER BY id DESC
        LIMIT 1
        """,
        (user_id,),
    ).fetchone()
    conn.close()
    if not row:
        prof = get_profile(user_id) or {}
        return {
            "status": "none",
            "verified": bool(prof.get("verified")),
            "message": "Sin solicitud de verificación",
        }
    result = _parse_json(row["result_json"], {})
    return {
        "status": row["status"],
        "verified": row["status"] == "approved",
        "curp": row["curp"],
        "face_match": bool(row["face_match"]),
        "face_distance": row["face_distance"],
        "created_at": row["created_at"],
        "messages": result.get("messages", []),
        "disclaimer": result.get("disclaimer", ""),
    }


def save_identity_verification(user_id: int, result: dict[str, Any]) -> dict[str, Any]:
    face = result.get("face") or {}
    status = result.get("status", "pending")
    curp = result.get("curp") or ""
    conn = get_conn()
    conn.execute(
        """
        INSERT INTO identity_verifications (user_id, status, curp, face_distance, face_match, result_json, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        """,
        (
            user_id,
            status,
            curp,
            float(face.get("distance") or 0),
            1 if face.get("match") else 0,
            json.dumps(result),
            _utc_now_iso(),
        ),
    )
    if result.get("approved"):
        prof = get_profile(user_id) or ensure_profile(user_id)
        prof["verified"] = True
        conn.execute(
            "UPDATE profiles SET data_json = ? WHERE user_id = ?",
            (json.dumps(prof), user_id),
        )
    conn.commit()
    conn.close()
    return get_identity_status(user_id)

