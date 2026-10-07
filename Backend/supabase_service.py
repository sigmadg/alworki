"""Integración con Supabase Auth (opcional)."""

from __future__ import annotations

import os
from typing import Any

from werkzeug.security import check_password_hash, generate_password_hash

from database import get_auth_connection, get_catalog_connection, is_postgres


def is_supabase_auth_enabled() -> bool:
    return bool(
        os.getenv("SUPABASE_URL", "").strip()
        and os.getenv("SUPABASE_SERVICE_ROLE_KEY", "").strip()
    )


def _client():
    from supabase import create_client

    return create_client(
        os.environ["SUPABASE_URL"],
        os.environ["SUPABASE_SERVICE_ROLE_KEY"],
    )


def register_user(
    email: str,
    password: str,
    firstname: str = "",
    lastname: str = "",
) -> dict[str, Any]:
    email_norm = email.strip().lower()

    if is_supabase_auth_enabled():
        sb = _client()
        meta = {"firstname": firstname, "lastname": lastname}
        result = sb.auth.admin.create_user(
            {
                "email": email_norm,
                "password": password,
                "email_confirm": True,
                "user_metadata": meta,
            }
        )
        auth_user = result.user
        if auth_user is None:
            raise ValueError("No se pudo crear el usuario en Supabase")
        return _upsert_app_user(
            email=email_norm,
            auth_uuid=str(auth_user.id),
            firstname=firstname,
            lastname=lastname,
            password_hash=None,
        )

    pwd_hash = generate_password_hash(password)

    if is_postgres():
        conn = get_catalog_connection()
        try:
            cur = conn.execute(
                """
                INSERT INTO app_users (email, password_hash, firstname, lastname)
                VALUES (?, ?, ?, ?)
                """,
                (email_norm, pwd_hash, firstname, lastname),
            )
            user_id = cur.lastrowid
            conn.commit()
        except Exception as exc:
            conn.close()
            if "unique" in str(exc).lower() or "duplicate" in str(exc).lower():
                raise ValueError("El correo ya está registrado") from exc
            raise
        conn.close()
        return {
            "id": user_id,
            "email": email_norm,
            "firstname": firstname,
            "lastname": lastname,
        }

    conn = get_auth_connection()
    try:
        cur = conn.execute(
            """
            INSERT INTO users (email, password_hash, firstname, lastname)
            VALUES (?, ?, ?, ?)
            """,
            (email_norm, pwd_hash, firstname, lastname),
        )
        user_id = cur.lastrowid
        conn.commit()
    except Exception as exc:
        conn.close()
        if "unique" in str(exc).lower() or "duplicate" in str(exc).lower():
            raise ValueError("El correo ya está registrado") from exc
        raise
    conn.close()

    import catalog_db

    name = f"{firstname} {lastname}".strip() or email_norm.split("@")[0]
    catalog_db.ensure_profile(user_id, name, email_norm)

    return {
        "id": user_id,
        "email": email_norm,
        "firstname": firstname,
        "lastname": lastname,
    }


def login_user(email: str, password: str) -> dict[str, Any]:
    email_norm = email.strip().lower()

    if is_supabase_auth_enabled():
        sb = _client()
        session = sb.auth.sign_in_with_password({"email": email_norm, "password": password})
        if session.user is None or session.session is None:
            raise ValueError("Correo o contraseña incorrectos")
        app_user = _upsert_app_user(
            email=email_norm,
            auth_uuid=str(session.user.id),
            firstname=session.user.user_metadata.get("firstname", ""),
            lastname=session.user.user_metadata.get("lastname", ""),
            password_hash=None,
        )
        app_user["supabase_access_token"] = session.session.access_token
        app_user["supabase_refresh_token"] = session.session.refresh_token
        return app_user

    conn = get_auth_connection()
    table = "app_users" if is_postgres() else "users"
    row = conn.execute(
        f"""
        SELECT id, email, password_hash, firstname, lastname, role
        FROM {table} WHERE LOWER(email) = ?
        """,
        (email_norm,),
    ).fetchone()
    conn.close()

    if not row or not row.get("password_hash"):
        raise ValueError("Correo o contraseña incorrectos")
    if not check_password_hash(row["password_hash"], password):
        raise ValueError("Correo o contraseña incorrectos")

    name = f"{row.get('firstname') or ''} {row.get('lastname') or ''}".strip()
    if not name:
        name = email_norm.split("@")[0]

    return {
        "id": row["id"],
        "email": row["email"],
        "firstname": row.get("firstname") or "",
        "lastname": row.get("lastname") or "",
        "name": name,
        "role": row.get("role") or "user",
    }


def resolve_user_id_from_auth_uuid(auth_uuid: str) -> int | None:
    conn = get_catalog_connection()
    row = conn.execute(
        "SELECT id FROM app_users WHERE auth_uuid = ?",
        (auth_uuid,),
    ).fetchone()
    conn.close()
    return int(row["id"]) if row else None


def _upsert_app_user(
    *,
    email: str,
    auth_uuid: str,
    firstname: str,
    lastname: str,
    password_hash: str | None,
) -> dict[str, Any]:
    conn = get_catalog_connection()
    existing = conn.execute(
        "SELECT id, firstname, lastname, role FROM app_users WHERE auth_uuid = ? OR LOWER(email) = ?",
        (auth_uuid, email.lower()),
    ).fetchone()
    if existing:
        user_id = existing["id"]
        conn.execute(
            """
            UPDATE app_users
            SET auth_uuid = ?, email = ?, firstname = ?, lastname = ?
            WHERE id = ?
            """,
            (auth_uuid, email, firstname, lastname, user_id),
        )
    else:
        cur = conn.execute(
            """
            INSERT INTO app_users (email, password_hash, auth_uuid, firstname, lastname)
            VALUES (?, ?, ?, ?, ?)
            """,
            (email, password_hash, auth_uuid, firstname, lastname),
        )
        user_id = cur.lastrowid
    conn.commit()
    conn.close()

    name = f"{firstname} {lastname}".strip() or email.split("@")[0]
    return {
        "id": user_id,
        "email": email,
        "firstname": firstname,
        "lastname": lastname,
        "name": name,
        "role": (existing or {}).get("role", "user"),
    }
