"""Validación de formato CURP (México)."""

from __future__ import annotations

import re

_CURP_RE = re.compile(
    r"^[A-Z]{4}"
    r"\d{6}"
    r"[HM]"
    r"[A-Z]{5}"
    r"[0-9A-Z]"
    r"\d$"
)


def normalize_curp(value: str | None) -> str:
    return (value or "").upper().strip()


def is_valid_curp(value: str | None) -> bool:
    curp = normalize_curp(value)
    if len(curp) != 18:
        return False
    return bool(_CURP_RE.match(curp))


def extract_curp_candidates(text: str) -> list[str]:
    upper = text.upper()
    return list(dict.fromkeys(m.group(0) for m in re.finditer(r"[A-Z]{4}\d{6}[HM][A-Z]{5}[0-9A-Z]\d", upper)))
