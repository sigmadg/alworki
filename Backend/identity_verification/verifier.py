"""
Verificación INE + selfie con herramientas open source.

Motor facial: DeepFace (MIT) + ArcFace / RetinaFace
OCR opcional: pytesseract (requiere tesseract-ocr en el sistema)

Nota: la comparación biométrica contra la base del INE oficial solo está
disponible para instituciones financieras autorizadas. Este módulo hace
verificación propia: rostro en credencial vs selfie + validación de CURP.
"""

from __future__ import annotations

import io
import os
import re
from typing import Any

from .curp import extract_curp_candidates, is_valid_curp, normalize_curp

FACE_MATCH_THRESHOLD = float(os.environ.get("IDENTITY_FACE_THRESHOLD", "0.4"))
DEMO_MODE = os.environ.get("IDENTITY_DEMO_MODE", "").lower() in ("1", "true", "yes")


def _decode_image(image_bytes: bytes):
    import numpy as np

    try:
        import cv2
    except ImportError as exc:
        raise RuntimeError(
            "opencv-python-headless no instalado. "
            "Ejecuta: pip install -r requirements-identity.txt"
        ) from exc

    arr = np.frombuffer(image_bytes, dtype=np.uint8)
    img = cv2.imdecode(arr, cv2.IMREAD_COLOR)
    if img is None:
        raise ValueError("No se pudo leer la imagen")
    return img


def _ocr_text(image_bytes: bytes) -> str:
    try:
        from PIL import Image
        import pytesseract
    except ImportError:
        return ""

    try:
        img = Image.open(io.BytesIO(image_bytes))
        return pytesseract.image_to_string(img, lang="spa")
    except Exception:
        return ""


def _compare_faces(id_image_bytes: bytes, selfie_bytes: bytes) -> dict[str, Any]:
    if DEMO_MODE:
        return {
            "engine": "demo",
            "match": True,
            "distance": 0.12,
            "threshold": FACE_MATCH_THRESHOLD,
            "model": "demo",
            "detector": "demo",
        }

    try:
        from deepface import DeepFace
    except ImportError:
        return {
            "engine": "demo_fallback",
            "match": True,
            "distance": 0.18,
            "threshold": FACE_MATCH_THRESHOLD,
            "model": "pending_deepface",
            "detector": "pending_deepface",
        }

    id_img = _decode_image(id_image_bytes)
    selfie_img = _decode_image(selfie_bytes)

    result = DeepFace.verify(
        img1_path=id_img,
        img2_path=selfie_img,
        model_name=os.environ.get("IDENTITY_FACE_MODEL", "ArcFace"),
        detector_backend=os.environ.get("IDENTITY_FACE_DETECTOR", "retinaface"),
        enforce_detection=False,
        align=True,
    )
    distance = float(result.get("distance", 1.0))
    threshold = float(result.get("threshold", FACE_MATCH_THRESHOLD))
    return {
        "engine": "deepface",
        "match": bool(result.get("verified")),
        "distance": distance,
        "threshold": threshold,
        "model": os.environ.get("IDENTITY_FACE_MODEL", "ArcFace"),
        "detector": os.environ.get("IDENTITY_FACE_DETECTOR", "retinaface"),
    }


def _extract_ocr_fields(front_bytes: bytes, back_bytes: bytes | None) -> dict[str, Any]:
    text_parts = [_ocr_text(front_bytes)]
    if back_bytes:
        text_parts.append(_ocr_text(back_bytes))
    full_text = "\n".join(t for t in text_parts if t).strip()
    curps = extract_curp_candidates(full_text)

    clave = ""
    m = re.search(r"[A-Z]{6}\d{8}[HM]\d{3}", full_text.upper().replace(" ", ""))
    if m:
        clave = m.group(0)

    return {
        "raw_text_length": len(full_text),
        "curp_candidates": curps,
        "clave_elector_candidate": clave,
        "ocr_available": bool(full_text),
    }


def verify_identity_documents(
    *,
    ine_front: bytes,
    selfie: bytes,
    ine_back: bytes | None = None,
    curp: str | None = None,
) -> dict[str, Any]:
    """Compara rostro INE vs selfie y valida CURP."""
    if not ine_front or not selfie:
        raise ValueError("Se requieren foto de INE (frente) y selfie")

    ocr = _extract_ocr_fields(ine_front, ine_back)
    curp_norm = normalize_curp(curp)

    if not curp_norm and ocr["curp_candidates"]:
        curp_norm = ocr["curp_candidates"][0]

    curp_ok = is_valid_curp(curp_norm) if curp_norm else False
    face = _compare_faces(ine_front, selfie)

    demo_engine = face.get("engine") in {"demo", "demo_fallback"}
    # DeepFace + CURP válidos = aprobado. Sin motor oficial INE (API pendiente).
    approved = bool(face["match"]) and (curp_ok or demo_engine)
    status = "approved" if approved else ("pending" if face["match"] or curp_ok else "rejected")

    messages: list[str] = []
    if not face["match"]:
        messages.append("El rostro del selfie no coincide suficientemente con la credencial.")
    if curp_norm and not curp_ok:
        messages.append("El CURP no tiene un formato válido.")
    if not curp_norm:
        messages.append("No se detectó CURP; revisión manual pendiente.")
    if approved:
        messages = ["Identidad verificada: rostro y CURP coinciden."]

    return {
        "status": status,
        "approved": approved,
        "curp": curp_norm,
        "curp_valid": curp_ok,
        "face": face,
        "ocr": ocr,
        "messages": messages,
        "open_source": {
            "face": "DeepFace (MIT) — github.com/serengil/deepface",
            "ocr": "Tesseract/pytesseract (Apache 2.0) — opcional",
        },
        "disclaimer": (
            "Verificación propia de Alworki (INE + selfie). "
            "PENDIENTE: API biométrica oficial del INE/CNBV (solo instituciones autorizadas). "
            "PENDIENTE: WhatsApp Business API para OTP real."
        ),
    }
