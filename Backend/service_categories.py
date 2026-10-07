"""Catálogo de oficios/categorías (espejo del cliente Flutter)."""

from __future__ import annotations

from typing import Any

CATEGORY_GROUPS: dict[str, list[dict[str, Any]]] = {
    "Hogar y reparaciones": [
        {"id": "plomeria", "label": "Plomería", "keywords": ["plomero", "fugas", "tuberías", "baño", "hogar"]},
        {"id": "electricidad", "label": "Electricidad", "keywords": ["electricista", "instalación", "luz", "hogar"]},
        {"id": "albanileria", "label": "Albañilería", "keywords": ["albañil", "mampostería", "obra", "hogar"]},
        {"id": "carpinteria", "label": "Carpintería", "keywords": ["carpintero", "muebles", "madera"]},
        {"id": "pintura", "label": "Pintura", "keywords": ["pintor", "brocha", "interiores"]},
        {"id": "limpieza", "label": "Limpieza doméstica", "keywords": ["limpieza", "aseo", "hogar"]},
        {"id": "jardineria", "label": "Jardinería", "keywords": ["jardinerero", "pasto", "plantas"]},
        {"id": "cerrajeria", "label": "Cerrajería", "keywords": ["cerrajero", "llaves", "chapas"]},
        {"id": "fumigacion", "label": "Fumigación", "keywords": ["plagas", "insectos"]},
        {"id": "impermeabilizacion", "label": "Impermeabilización", "keywords": ["goteras", "techo"]},
    ],
    "Salud y cuidado": [
        {"id": "enfermeria", "label": "Enfermería", "keywords": ["enfermera", "enfermero", "curaciones", "salud"]},
        {"id": "cuidadores", "label": "Cuidadores", "keywords": ["cuidador", "cuidadora", "adulto mayor"]},
        {"id": "geriatria", "label": "Cuidado geriátrico", "keywords": ["geriátrico", "tercera edad"]},
        {"id": "fisioterapia", "label": "Fisioterapia", "keywords": ["fisioterapeuta", "rehabilitación"]},
        {"id": "nutricion", "label": "Nutrición", "keywords": ["nutriólogo", "dieta", "alimentación"]},
        {"id": "psicologia", "label": "Psicología", "keywords": ["psicólogo", "terapia", "salud mental"]},
        {"id": "primeros_auxilios", "label": "Primeros auxilios", "keywords": ["emergencias", "rcp"]},
    ],
    "Mascotas": [
        {"id": "veterinarios", "label": "Veterinarios", "keywords": ["veterinario", "veterinaria", "mascota", "perro", "gato", "cuidado animal"]},
        {"id": "paseo_mascotas", "label": "Paseo de mascotas", "keywords": ["paseador", "perros", "paseo", "cuidado animal"]},
        {"id": "estetica_canina", "label": "Estética canina", "keywords": ["baño", "grooming", "peluquería canina"]},
        {"id": "adiestramiento", "label": "Adiestramiento", "keywords": ["entrenador", "obediencia"]},
        {"id": "cuidado_gatos", "label": "Cuidado de gatos", "keywords": ["cat sitter", "gatos"]},
    ],
    "Educación y cuidado infantil": [
        {"id": "nineras", "label": "Niñeras", "keywords": ["niñera", "niñero", "babysitter", "hijos", "educación"]},
        {"id": "apoyo_escolar", "label": "Apoyo escolar", "keywords": ["tareas", "refuerzo", "primaria", "educación"]},
        {"id": "educacion_especial", "label": "Educación especial", "keywords": ["inclusión", "necesidades especiales"]},
        {"id": "cuidado_infantil", "label": "Cuidado infantil", "keywords": ["guardería", "bebés"]},
    ],
    "Educación e idiomas": [
        {"id": "ingles", "label": "Clases de inglés", "keywords": ["inglés", "english", "conversación", "educación"]},
        {"id": "otros_idiomas", "label": "Otros idiomas", "keywords": ["francés", "alemán", "italiano", "educación"]},
        {"id": "musica", "label": "Música", "keywords": ["guitarra", "piano", "canto", "clases", "música"]},
        {"id": "arte", "label": "Arte y pintura", "keywords": ["pintura", "dibujo", "escultura"]},
        {"id": "danza", "label": "Danza", "keywords": ["baile", "ballet", "salsa"]},
        {"id": "clases_particulares", "label": "Clases particulares", "keywords": ["tutor", "matemáticas", "física", "educación"]},
    ],
    "Gastronomía": [
        {"id": "cocina_casera", "label": "Cocina casera", "keywords": ["cocina", "comida", "chef", "gastronomía"]},
        {"id": "reposteria", "label": "Repostería", "keywords": ["pasteles", "postres", "pan", "gastronomía"]},
        {"id": "meal_prep", "label": "Meal prep", "keywords": ["meal prep", "raciones", "semanal", "gastronomía"]},
        {"id": "chef_domicilio", "label": "Chef a domicilio", "keywords": ["chef", "cena", "evento"]},
        {"id": "bartender", "label": "Bartender", "keywords": ["bebidas", "coctelería", "bar"]},
    ],
    "Belleza y bienestar": [
        {"id": "peluqueria", "label": "Peluquería", "keywords": ["peluquero", "corte", "cabello"]},
        {"id": "barberia", "label": "Barbería", "keywords": ["barbero", "barba"]},
        {"id": "manicure", "label": "Manicure y uñas", "keywords": ["uñas", "gelish"]},
        {"id": "maquillaje", "label": "Maquillaje", "keywords": ["makeup", "novias"]},
        {"id": "masajes", "label": "Masajes", "keywords": ["masajista", "relajación", "spa"]},
    ],
    "Tecnología": [
        {"id": "soporte_tecnico", "label": "Soporte técnico", "keywords": ["computadora", "pc", "software"]},
        {"id": "reparacion_celulares", "label": "Reparación de celulares", "keywords": ["celular", "pantalla", "móvil"]},
        {"id": "diseno_web", "label": "Diseño web", "keywords": ["página web", "diseño", "ui"]},
        {"id": "marketing_digital", "label": "Marketing digital", "keywords": ["redes sociales", "seo", "publicidad"]},
    ],
    "Transporte y logística": [
        {"id": "mensajeria", "label": "Mensajería", "keywords": ["mandados", "paquetería", "entregas"]},
        {"id": "mudanzas", "label": "Mudanzas", "keywords": ["mudanza", "carga", "traslado"]},
        {"id": "chofer", "label": "Chofer", "keywords": ["conductor", "traslados"]},
        {"id": "mecanico", "label": "Mecánico automotriz", "keywords": ["auto", "taller", "reparación"]},
    ],
    "Eventos": [
        {"id": "fotografia", "label": "Fotografía", "keywords": ["fotógrafo", "sesión", "bodas"]},
        {"id": "dj", "label": "DJ", "keywords": ["música", "fiesta", "sonido"]},
        {"id": "animacion", "label": "Animación", "keywords": ["animador", "fiestas infantiles"]},
        {"id": "decoracion_eventos", "label": "Decoración de eventos", "keywords": ["globos", "fiesta", "decoración"]},
        {"id": "catering", "label": "Catering", "keywords": ["banquetes", "comida para eventos"]},
    ],
    "Legal y administrativo": [
        {"id": "contabilidad", "label": "Contabilidad", "keywords": ["contador", "impuestos", "sat"]},
        {"id": "asesoria_legal", "label": "Asesoría legal", "keywords": ["abogado", "legal", "contratos"]},
        {"id": "tramites", "label": "Trámites", "keywords": ["gestoría", "papeles", "documentos"]},
    ],
}


def list_categories() -> list[dict[str, Any]]:
    out: list[dict[str, Any]] = []
    for group, items in CATEGORY_GROUPS.items():
        for item in items:
            out.append({**item, "group": group})
    return out


def category_search_terms() -> dict[str, set[str]]:
  terms: dict[str, set[str]] = {}
  for group, items in CATEGORY_GROUPS.items():
      g = group.lower()
      for item in items:
          label = item["label"].lower()
          bucket = terms.setdefault(label, set())
          bucket.add(label)
          bucket.add(g)
          for kw in item.get("keywords", []):
              bucket.add(kw.lower())
  return terms


def query_matches_catalog(query: str) -> bool:
    q = query.strip().lower()
    if not q:
        return False
    for terms in category_search_terms().values():
        if any(q in t or t in q for t in terms):
            return True
    for group in CATEGORY_GROUPS:
        gl = group.lower()
        if q in gl or gl in q:
            return True
    return False


def resolve_trade(query: str) -> dict[str, Any] | None:
    """Resuelve un oficio a partir de texto libre (ej. carpintero → Carpintería)."""
    q = query.strip().lower()
    if not q:
        return None
    best: dict[str, Any] | None = None
    best_len = 10_000
    for group, items in CATEGORY_GROUPS.items():
        for item in items:
            terms = [item["label"].lower(), *[k.lower() for k in item.get("keywords", [])]]
            if any(q == t or q in t or t in q for t in terms):
                hit = min((len(t) for t in terms if q == t or q in t or t in q), default=99)
                if hit < best_len:
                    best_len = hit
                    best = {**item, "group": group, "terms": terms}
    return best


def split_requirements(raw: Any) -> list[str]:
    if raw is None:
        return []
    if isinstance(raw, (list, tuple)):
        parts = [str(x) for x in raw]
    else:
        parts = str(raw).replace(";", ",").split(",")
    out: list[str] = []
    seen: set[str] = set()
    for part in parts:
        token = " ".join(part.strip().lower().split())
        if len(token) < 2 or token in seen:
            continue
        seen.add(token)
        out.append(token)
    return out[:12]


def catalog_sql_like_patterns(query: str) -> list[str]:
    """Patrones extra LIKE para ampliar búsqueda por oficios del catálogo."""
    q = query.strip().lower()
    if not q:
        return []
    patterns: set[str] = {f"%{q}%"}
    for group, items in CATEGORY_GROUPS.items():
        gl = group.lower()
        if q in gl or gl in q:
            patterns.add(f"%{group.lower()}%")
        for item in items:
            label = item["label"].lower()
            keywords = [label, *[k.lower() for k in item.get("keywords", [])]]
            if any(q in k or k in q for k in keywords):
                patterns.add(f"%{item['label'].lower()}%")
                patterns.add(f"%{group.lower()}%")
                for k in item.get("keywords", []):
                    patterns.add(f"%{k.lower()}%")
    return list(patterns)
