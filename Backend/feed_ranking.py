"""
Ranking de feed y sugerencias de perfiles — inspirado en el feed de Instagram.

Señales (pesos por defecto):
  - Interés (~35%): afinidad con categorías/oficios del usuario
  - Relación (~30%): sigues, confías, contactos
  - Engagement (~20%): likes, comentarios, guardados (prueba social)
  - Recencia (~15%): decaimiento exponencial en el tiempo
  + bonus verificado / cercanía
  + reordenación por diversidad de autores
"""

from __future__ import annotations

import math
import re
from datetime import datetime, timezone
from typing import Any

WEIGHT_INTEREST = 0.35
WEIGHT_RELATIONSHIP = 0.30
WEIGHT_ENGAGEMENT = 0.20
WEIGHT_RECENCY = 0.15

RECENCY_HALF_LIFE_HOURS = 72.0


def _parse_ts(value: str) -> datetime:
    try:
        if value.endswith("Z"):
            return datetime.fromisoformat(value.replace("Z", "+00:00"))
        return datetime.fromisoformat(value)
    except (TypeError, ValueError):
        return datetime.now(timezone.utc)


def _tokenize(text: str) -> set[str]:
    return {t for t in re.findall(r"[a-záéíóúñ0-9]+", (text or "").lower()) if len(t) > 2}


def _interest_score(post: dict[str, Any], signals: dict[str, Any]) -> float:
    keywords: set[str] = set()
    for skill in signals.get("skills", []):
        keywords |= _tokenize(str(skill))
    for prof in signals.get("professions", []):
        keywords |= _tokenize(str(prof))
    for cat, weight in (signals.get("categoryAffinity") or {}).items():
        for _ in range(min(int(weight), 5)):
            keywords |= _tokenize(str(cat))

    if not keywords:
        return 0.35

    post_text = " ".join(
        [
            str(post.get("description", "")),
            str(post.get("card_title", "")),
            str(post.get("category", "")),
            str(post.get("location", "")),
        ]
    )
    post_tokens = _tokenize(post_text)
    if not post_tokens:
        return 0.2

    overlap = len(keywords & post_tokens)
    return min(1.0, overlap / max(3, len(keywords) * 0.25))


def _relationship_score(post: dict[str, Any], signals: dict[str, Any]) -> float:
    user = post.get("user") or {}
    uid = user.get("id")
    if uid is None:
        return 0.0
    if uid == signals.get("userId"):
        return 0.0

    score = 0.0
    if user.get("following"):
        score += 0.55
    if uid in set(signals.get("trustedUserIds") or []):
        score += 0.35
    if uid in set(signals.get("contactUserIds") or []):
        score += 0.45
    if user.get("verified"):
        score += 0.12
    return min(1.0, score)


def _engagement_score(post: dict[str, Any]) -> float:
    likes = float(post.get("likes") or 0)
    comments = float(post.get("comments") or 0)
    saved = 1.0 if post.get("saved") else 0.0
    raw = math.log1p(likes) * 0.35 + comments * 0.08 + saved * 0.4
    return min(1.0, raw / 3.0)


def _recency_score(post: dict[str, Any], now: datetime | None = None) -> float:
    now = now or datetime.now(timezone.utc)
    ts = _parse_ts(str(post.get("timestamp", "")))
    if ts.tzinfo is None:
        ts = ts.replace(tzinfo=timezone.utc)
    hours = max(0.0, (now - ts).total_seconds() / 3600.0)
    return math.exp(-hours / RECENCY_HALF_LIFE_HOURS)


def _proximity_bonus(post: dict[str, Any], signals: dict[str, Any]) -> float:
    if not signals.get("proximityEnabled"):
        return 0.0
    lat = post.get("lat")
    lng = post.get("lng")
    center_lat = signals.get("centerLat")
    center_lng = signals.get("centerLng")
    radius = float(signals.get("radiusKm") or 15.0)
    if lat is None or lng is None or center_lat is None or center_lng is None:
        return 0.0
    d_lat = (float(lat) - float(center_lat)) * 111.0
    d_lng = (float(lng) - float(center_lng)) * 111.0 * math.cos(math.radians(float(center_lat)))
    km = math.hypot(d_lat, d_lng)
    if km > radius:
        return 0.0
    return 0.15 * (1.0 - km / radius)


def score_feed_post(post: dict[str, Any], signals: dict[str, Any], now: datetime | None = None) -> float:
    interest = _interest_score(post, signals)
    relationship = _relationship_score(post, signals)
    engagement = _engagement_score(post)
    recency = _recency_score(post, now)
    base = (
        WEIGHT_INTEREST * interest
        + WEIGHT_RELATIONSHIP * relationship
        + WEIGHT_ENGAGEMENT * engagement
        + WEIGHT_RECENCY * recency
    )
    return base + _proximity_bonus(post, signals)


def rank_feed_posts(posts: list[dict[str, Any]], signals: dict[str, Any]) -> list[dict[str, Any]]:
    """Ordena publicaciones y aplica diversidad de autores."""
    now = datetime.now(timezone.utc)
    scored: list[tuple[float, dict[str, Any]]] = []
    for post in posts:
        s = score_feed_post(post, signals, now)
        enriched = dict(post)
        enriched["recommended"] = s >= 0.45
        enriched["_rankScore"] = round(s, 4)
        scored.append((s, enriched))

    scored.sort(key=lambda item: item[0], reverse=True)

    # Diversidad: penalizar autores repetidos en ventana deslizante (estilo Instagram)
    result: list[dict[str, Any]] = []
    recent_authors: list[int | None] = []
    pool = [p for _, p in scored]

    while pool:
        best_idx = 0
        best_adjusted = -1.0
        for i, candidate in enumerate(pool[:8]):
            author = (candidate.get("user") or {}).get("id")
            penalty = sum(0.18 for a in recent_authors[-3:] if a == author)
            adjusted = float(candidate.get("_rankScore", 0)) - penalty
            if adjusted > best_adjusted:
                best_adjusted = adjusted
                best_idx = i
        picked = pool.pop(best_idx)
        author = (picked.get("user") or {}).get("id")
        recent_authors.append(author)
        result.append(picked)

    return result


def score_profile_candidate(candidate: dict[str, Any], signals: dict[str, Any]) -> float:
    uid = candidate.get("userId") or (candidate.get("user") or {}).get("id")
    if uid is None or uid == signals.get("userId"):
        return -1.0
    if uid in set(signals.get("trustedUserIds") or []):
        return -1.0
    if (candidate.get("user") or {}).get("following"):
        return -1.0

    score = 0.25
    user = candidate.get("user") or {}
    if user.get("verified"):
        score += 0.2

    caption = " ".join(
        [
            str(candidate.get("caption", "")),
            str(candidate.get("card_title", "")),
            str(candidate.get("cardTitle", "")),
            str(candidate.get("profession", "")),
        ]
    )
    fake_post = {"description": caption, "card_title": caption, "category": caption, "user": user}
    score += 0.45 * _interest_score(fake_post, signals)
    score += 0.25 * _recency_score({"timestamp": candidate.get("timestamp", "")})
    if uid in set(signals.get("contactUserIds") or []):
        score += 0.15
    return score


def rank_profile_suggestions(
    candidates: list[dict[str, Any]],
    signals: dict[str, Any],
    limit: int = 12,
) -> list[dict[str, Any]]:
    scored = []
    for c in candidates:
        s = score_profile_candidate(c, signals)
        if s < 0:
            continue
        item = dict(c)
        item["_rankScore"] = round(s, 4)
        item["recommended"] = s >= 0.4
        scored.append((s, item))
    scored.sort(key=lambda x: x[0], reverse=True)
    return [item for _, item in scored[:limit]]


def build_signals_from_profile(
    user_id: int | None,
    profile: dict[str, Any] | None,
    *,
    contact_user_ids: list[int] | None = None,
    proximity_enabled: bool = False,
    center_lat: float | None = None,
    center_lng: float | None = None,
    radius_km: float = 15.0,
) -> dict[str, Any]:
    prof = profile or {}
    feed_signals = prof.get("feedSignals") or {}
    skills = [s.get("name", "") for s in prof.get("skills", []) if isinstance(s, dict)]
    return {
        "userId": user_id,
        "skills": skills,
        "professions": list(prof.get("professions") or []),
        "trustedUserIds": list(feed_signals.get("trustedUserIds") or []),
        "categoryAffinity": dict(feed_signals.get("categoryAffinity") or {}),
        "contactUserIds": list(contact_user_ids or []),
        "proximityEnabled": proximity_enabled,
        "centerLat": center_lat,
        "centerLng": center_lng,
        "radiusKm": radius_km,
    }
