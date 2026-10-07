#!/usr/bin/env python3
"""Pruebas de funcionalidad del loop: auth, feed, búsqueda e intercambios."""
from __future__ import annotations

import os
import sys
import time
import uuid

import requests

BASE = os.environ.get("ALWORKI_API_URL", "http://127.0.0.1:5002").rstrip("/")


def _unique_email() -> str:
    return f"loop_{uuid.uuid4().hex[:10]}@alworki.test"


def _auth(email: str, password: str = "LoopPass123!") -> dict:
    requests.post(
        f"{BASE}/api/auth/register",
        json={"email": email, "password": password, "firstname": "Loop", "lastname": "Tester"},
        timeout=8,
    )
    res = requests.post(
        f"{BASE}/api/auth/login",
        json={"email": email, "password": password},
        timeout=8,
    )
    res.raise_for_status()
    data = res.json()
    assert data.get("access_token"), data
    return data


def _headers(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}


def test_health() -> None:
    res = requests.get(f"{BASE}/health", timeout=5)
    res.raise_for_status()


def test_feed_and_search() -> None:
    feed = requests.get(f"{BASE}/api/feed", timeout=8)
    feed.raise_for_status()
    posts = feed.json()
    assert isinstance(posts, list)
    assert posts, "el feed no debe estar vacío en demo"

    search = requests.get(f"{BASE}/api/cards/search", params={"q": "plomer"}, timeout=8)
    search.raise_for_status()
    cards = search.json()
    assert isinstance(cards, list)
    assert any("plom" in (c.get("title") or "").lower() or "plom" in (c.get("category") or "").lower()
               or "plom" in (c.get("description") or "").lower() for c in cards), cards


def test_exchange_requires_auth() -> None:
    res = requests.get(f"{BASE}/api/exchange", timeout=8)
    assert res.status_code == 401


def test_exchange_lifecycle() -> None:
    a = _auth(_unique_email())
    b = _auth(_unique_email())
    token_a, token_b = a["access_token"], b["access_token"]
    user_b = int((b.get("user") or {}).get("id") or 0)
    if user_b <= 0:
        me = requests.get(f"{BASE}/api/users/me/profile", headers=_headers(token_b), timeout=8)
        me.raise_for_status()
        user_b = int(me.json()["id"])

    created = requests.post(
        f"{BASE}/api/exchange",
        headers=_headers(token_a),
        json={
            "title": "Inglés por plomería",
            "description": "2 horas de inglés a cambio de una fuga",
            "targetUserId": user_b,
        },
        timeout=8,
    )
    assert created.status_code == 201, created.text
    item = created.json()
    assert item["status"] == "pendiente"
    exchange_id = item["id"]

    forbidden = requests.patch(
        f"{BASE}/api/exchange/{exchange_id}",
        headers=_headers(token_a),
        json={"status": "aceptada"},
        timeout=8,
    )
    assert forbidden.status_code == 403, forbidden.text

    accepted = requests.patch(
        f"{BASE}/api/exchange/{exchange_id}",
        headers=_headers(token_b),
        json={"status": "aceptada"},
        timeout=8,
    )
    assert accepted.status_code == 200, accepted.text
    assert accepted.json()["status"] == "aceptada"

    done = requests.patch(
        f"{BASE}/api/exchange/{exchange_id}",
        headers=_headers(token_a),
        json={"status": "completada"},
        timeout=8,
    )
    assert done.status_code == 200, done.text
    assert done.json()["status"] == "completada"

    projects = requests.get(f"{BASE}/api/projects", headers=_headers(token_a), timeout=8)
    projects.raise_for_status()
    named = [p for p in projects.json() if p.get("name") == "Inglés por plomería"]
    assert named, projects.json()
    tracked = named[0]
    assert tracked.get("trackingNumber")
    assert tracked.get("deliveryStatus") == "en_trabajo"


def test_publish_feed_requires_token() -> None:
    res = requests.post(f"{BASE}/api/feed", json={"description": "hola"}, timeout=8)
    assert res.status_code == 401


def test_project_story_and_follow() -> None:
    a = _auth(_unique_email())
    b = _auth(_unique_email())
    token_a, token_b = a["access_token"], b["access_token"]
    user_b = int((b.get("user") or {}).get("id") or 0)

    created = requests.post(
        f"{BASE}/api/projects",
        headers=_headers(token_a),
        json={
            "name": "Guitarra ↔ cocina",
            "description": "Clases de guitarra por meal prep",
            "publishToFeed": True,
        },
        timeout=8,
    )
    assert created.status_code == 201, created.text
    project_id = created.json()["id"]

    follow_p = requests.post(
        f"{BASE}/api/projects/{project_id}/follow",
        headers=_headers(token_b),
        timeout=8,
    )
    assert follow_p.status_code == 200, follow_p.text
    assert follow_p.json()["followed"] is True

    story = requests.post(
        f"{BASE}/api/stories",
        headers=_headers(token_a),
        json={"caption": "Hoy doy clase de guitarra", "image_url": "background3.png"},
        timeout=8,
    )
    assert story.status_code == 201, story.text
    assert story.json()["caption"] == "Hoy doy clase de guitarra"

    if user_b > 0:
        follow_u = requests.post(
            f"{BASE}/api/users/{user_b}/follow",
            headers=_headers(token_a),
            timeout=8,
        )
        assert follow_u.status_code == 200, follow_u.text
        assert follow_u.json()["following"] is True
        listed = requests.get(f"{BASE}/api/users/me/following", headers=_headers(token_a), timeout=8)
        listed.raise_for_status()
        assert user_b in listed.json()["ids"]


def test_project_delivery_tracking() -> None:
    a = _auth(_unique_email())
    token = a["access_token"]
    created = requests.post(
        f"{BASE}/api/projects",
        headers=_headers(token),
        json={
            "name": "Closet a medida",
            "description": "Instalación de closet",
            "requirements": ["muebles", "madera"],
            "publishToFeed": False,
        },
        timeout=8,
    )
    assert created.status_code == 201, created.text
    project = created.json()
    project_id = project["id"]
    assert project["trackingNumber"]
    assert project["deliveryStatus"] == "solicitado"
    assert "muebles" in project["requirements"]

    started = requests.patch(
        f"{BASE}/api/projects/{project_id}",
        headers=_headers(token),
        json={"status": "en_trabajo"},
        timeout=8,
    )
    assert started.status_code == 200, started.text
    assert started.json()["deliveryStatus"] == "en_trabajo"

    delivered = requests.post(
        f"{BASE}/api/projects/{project_id}/delivery",
        headers=_headers(token),
        json={"message": "Closet instalado"},
        timeout=8,
    )
    assert delivered.status_code == 200, delivered.text
    assert delivered.json()["deliveryStatus"] == "entregado"
    assert delivered.json()["delivery"]["message"] == "Closet instalado"

    confirmed = requests.patch(
        f"{BASE}/api/projects/{project_id}",
        headers=_headers(token),
        json={"status": "confirmado"},
        timeout=8,
    )
    assert confirmed.status_code == 200, confirmed.text
    assert confirmed.json()["deliveryStatus"] == "confirmado"
    assert confirmed.json()["status"] == "completado"


def test_nearest_carpenter_meets_requirements() -> None:
    res = requests.get(
        f"{BASE}/api/jobs/match",
        params={
            "q": "carpintero",
            "requirements": "muebles,madera,herramientas",
            "lat": 19.4326,
            "lng": -99.1332,
            "radius_km": 20,
        },
        timeout=8,
    )
    res.raise_for_status()
    cards = res.json()
    assert cards, cards
    first = cards[0]
    blob = f"{first.get('title')} {first.get('description')} {first.get('category')}".lower()
    assert "carpinter" in blob or "madera" in blob or "mueble" in blob, first
    assert first.get("meetsRequirements") is True, first
    assert first.get("distanceKm") is not None, first
    if len(cards) > 1 and cards[1].get("meetsRequirements") and cards[1].get("distanceKm") is not None:
        assert first["distanceKm"] <= cards[1]["distanceKm"] + 0.01


def main() -> int:
    started = time.time()
    tests = [
        test_health,
        test_feed_and_search,
        test_exchange_requires_auth,
        test_publish_feed_requires_token,
        test_exchange_lifecycle,
        test_project_story_and_follow,
        test_project_delivery_tracking,
        test_nearest_carpenter_meets_requirements,
    ]
    failed = 0
    for fn in tests:
        try:
            fn()
            print(f"PASS  {fn.__name__}")
        except Exception as exc:  # noqa: BLE001
            failed += 1
            print(f"FAIL  {fn.__name__}: {exc}")
    print(f"\n{len(tests) - failed}/{len(tests)} ok en {time.time() - started:.1f}s")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
