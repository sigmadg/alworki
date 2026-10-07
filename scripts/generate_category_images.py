#!/usr/bin/env python3
"""
Genera imágenes de categorías con Stable Diffusion WebUI o ComfyUI (Flux/tinflux).

Requisitos:
  - WebUI: bash scripts/start_stable_diffusion.sh  (modelos SD clásicos)
  - ComfyUI + Flux: bash scripts/start_comfyui.sh  (tinflux13DQ_v10)
  - pip install requests pillow

Uso:
  python3 scripts/generate_category_images.py
  python3 scripts/generate_category_images.py --ids plomeria,veterinarios
  python3 scripts/generate_category_images.py --dry-run
  python3 scripts/generate_category_images.py --force
"""
from __future__ import annotations

import argparse
import base64
import io
import json
import sys
import time
import uuid
from pathlib import Path

try:
    import requests
except ImportError:
    print("Instala requests: pip install requests")
    sys.exit(1)

try:
    from PIL import Image
except ImportError:
    print("Instala pillow: pip install pillow")
    sys.exit(1)

ROOT = Path(__file__).resolve().parents[1]
PROMPTS_FILE = ROOT / "scripts" / "category_image_prompts.json"
SD_API = "http://127.0.0.1:7860"
COMFY_API = "http://127.0.0.1:8188"
MIN_BYTES = 20_000


def load_config() -> dict:
    with PROMPTS_FILE.open(encoding="utf-8") as f:
        return json.load(f)


def is_valid_image(raw: bytes) -> bool:
    if len(raw) < MIN_BYTES:
        return False
    im = Image.open(io.BytesIO(raw))
    if im.mode != "RGB":
        im = im.convert("RGB")
    extrema = im.getextrema()
    if all(lo == hi for lo, hi in extrema[:3]):
        return False
    return True


# --- WebUI (A1111) ---

def wait_for_webui(api_base: str, timeout: int = 300) -> None:
    print(f"Esperando WebUI en {api_base} …")
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            r = requests.get(f"{api_base}/sdapi/v1/sd-models", timeout=5)
            if r.status_code == 200:
                print("WebUI lista.")
                return
        except requests.RequestException:
            pass
        time.sleep(3)
    raise SystemExit(f"Timeout: no responde {api_base}. ¿Corriste start_stable_diffusion.sh?")


def set_webui_model(api_base: str, model_name: str, settings: dict) -> None:
    models = requests.get(f"{api_base}/sdapi/v1/sd-models", timeout=30).json()
    target = next((m for m in models if model_name in m.get("title", "") or model_name in m.get("model_name", "")), None)
    if not target:
        titles = [m.get("title", "?") for m in models[:12]]
        raise SystemExit(f"Modelo no encontrado: {model_name}\nDisponibles: {titles}")
    print(f"Cargando modelo: {target['title']} …")
    requests.post(
        f"{api_base}/sdapi/v1/options",
        json={"sd_model_checkpoint": target["title"]},
        timeout=120,
    )
    time.sleep(10)
    raw = _request_webui_image(api_base, f"{settings['style_prefix']}, test illustration", settings)
    if not is_valid_image(raw):
        raise SystemExit(
            f"El modelo {model_name} no generó imágenes válidas (salida gris o vacía). "
            "Para Flux/tinflux usa backend comfyui en category_image_prompts.json."
        )
    print(f"Modelo verificado: {target['title']} ({len(raw) // 1024} KB)")


def _request_webui_image(api_base: str, prompt: str, settings: dict) -> bytes:
    payload = {
        "prompt": prompt,
        "negative_prompt": settings["negative_prompt"],
        "width": settings["width"],
        "height": settings["height"],
        "steps": settings["steps"],
        "cfg_scale": settings["cfg_scale"],
        "sampler_name": settings["sampler_name"],
        "batch_size": 1,
        "n_iter": 1,
        "save_images": False,
    }
    r = requests.post(f"{api_base}/sdapi/v1/txt2img", json=payload, timeout=600)
    r.raise_for_status()
    data = r.json()
    if not data.get("images"):
        raise RuntimeError("API no devolvió imágenes")
    b64 = data["images"][0]
    return base64.b64decode(b64.split(",", 1)[-1])


def generate_webui(api_base: str, cat: dict, settings: dict) -> bytes:
    prompt = f"{settings['style_prefix']}, {cat['scene']}"
    raw = _request_webui_image(api_base, prompt, settings)
    if not is_valid_image(raw):
        raise RuntimeError("imagen inválida (gris o demasiado pequeña)")
    return raw


# --- ComfyUI (Flux / tinflux) ---

def wait_for_comfyui(api_base: str, timeout: int = 300) -> None:
    print(f"Esperando ComfyUI en {api_base} …")
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            r = requests.get(f"{api_base}/system_stats", timeout=5)
            if r.status_code == 200:
                print("ComfyUI lista.")
                return
        except requests.RequestException:
            pass
        time.sleep(3)
    raise SystemExit(f"Timeout: no responde {api_base}. ¿Corriste start_comfyui.sh?")


def _build_comfy_workflow(prompt: str, settings: dict, seed: int) -> dict:
    comfy = settings.get("comfyui", {})
    unet = comfy.get("unet", settings["model"])
    clip_l = comfy.get("clip_l", "clip_l.safetensors")
    t5xxl = comfy.get("t5xxl", "t5xxl_fp8_e4m3fn.safetensors")
    vae = comfy.get("vae", "ae.safetensors")
    weight_dtype = comfy.get("weight_dtype", "default")
    guidance = settings.get("guidance", 3.5)
    scheduler = settings.get("scheduler", "simple")
    prefix = f"alworki_{uuid.uuid4().hex[:8]}"

    return {
        "1": {
            "class_type": "UNETLoader",
            "inputs": {"unet_name": unet, "weight_dtype": weight_dtype},
        },
        "2": {
            "class_type": "DualCLIPLoader",
            "inputs": {"clip_name1": clip_l, "clip_name2": t5xxl, "type": "flux"},
        },
        "3": {
            "class_type": "VAELoader",
            "inputs": {"vae_name": vae},
        },
        "4": {
            "class_type": "CLIPTextEncodeFlux",
            "inputs": {
                "clip": ["2", 0],
                "clip_l": prompt,
                "t5xxl": prompt,
                "guidance": guidance,
            },
        },
        "5": {
            "class_type": "ConditioningZeroOut",
            "inputs": {"conditioning": ["4", 0]},
        },
        "6": {
            "class_type": "EmptySD3LatentImage",
            "inputs": {
                "width": settings["width"],
                "height": settings["height"],
                "batch_size": 1,
            },
        },
        "7": {
            "class_type": "KSampler",
            "inputs": {
                "model": ["1", 0],
                "positive": ["4", 0],
                "negative": ["5", 0],
                "latent_image": ["6", 0],
                "seed": seed,
                "steps": settings["steps"],
                "cfg": settings.get("cfg_scale", 1),
                "sampler_name": settings["sampler_name"],
                "scheduler": scheduler,
                "denoise": 1.0,
            },
        },
        "8": {
            "class_type": "VAEDecode",
            "inputs": {"samples": ["7", 0], "vae": ["3", 0]},
        },
        "9": {
            "class_type": "SaveImage",
            "inputs": {"images": ["8", 0], "filename_prefix": prefix},
        },
    }


def _comfy_queue_and_fetch(api_base: str, workflow: dict, timeout: int = 900) -> bytes:
    client_id = str(uuid.uuid4())
    r = requests.post(
        f"{api_base}/prompt",
        json={"prompt": workflow, "client_id": client_id},
        timeout=60,
    )
    r.raise_for_status()
    body = r.json()
    if body.get("node_errors"):
        raise RuntimeError(f"Errores en workflow: {body['node_errors']}")
    prompt_id = body["prompt_id"]

    deadline = time.time() + timeout
    while time.time() < deadline:
        hist = requests.get(f"{api_base}/history/{prompt_id}", timeout=30).json()
        if prompt_id in hist:
            entry = hist[prompt_id]
            if entry.get("status", {}).get("status_str") == "error":
                msgs = entry.get("status", {}).get("messages", [])
                raise RuntimeError(f"ComfyUI error: {msgs}")
            outputs = entry.get("outputs", {})
            for node_out in outputs.values():
                for img in node_out.get("images", []):
                    params = {
                        "filename": img["filename"],
                        "subfolder": img.get("subfolder", ""),
                        "type": img.get("type", "output"),
                    }
                    view = requests.get(f"{api_base}/view", params=params, timeout=60)
                    view.raise_for_status()
                    return view.content
            raise RuntimeError("ComfyUI terminó sin imágenes en outputs")
        time.sleep(2)
    raise RuntimeError(f"Timeout esperando prompt {prompt_id}")


def verify_comfy_model(settings: dict) -> None:
    comfy = settings.get("comfyui", {})
    api = comfy.get("api", COMFY_API).rstrip("/")
    wait_for_comfyui(api)
    prompt = f"{settings['style_prefix']}, test illustration"
    workflow = _build_comfy_workflow(prompt, settings, seed=42)
    print(f"Verificando tinflux en ComfyUI ({settings['model']}) …")
    raw = _comfy_queue_and_fetch(api, workflow)
    if not is_valid_image(raw):
        raise SystemExit("tinflux no generó imagen válida en ComfyUI.")
    print(f"Modelo verificado ({len(raw) // 1024} KB)")


def generate_comfyui(api_base: str, cat: dict, settings: dict, seed: int) -> bytes:
    prompt = f"{settings['style_prefix']}, {cat['scene']}"
    workflow = _build_comfy_workflow(prompt, settings, seed=seed)
    raw = _comfy_queue_and_fetch(api_base, workflow)
    if not is_valid_image(raw):
        raise RuntimeError("imagen inválida (gris o demasiado pequeña)")
    return raw


def main() -> None:
    parser = argparse.ArgumentParser(description="Genera imágenes de categorías Alworki")
    parser.add_argument("--ids", help="IDs separados por coma (default: todos)")
    parser.add_argument("--dry-run", action="store_true", help="Solo muestra prompts")
    parser.add_argument("--force", action="store_true", help="Regenerar aunque el archivo ya exista")
    parser.add_argument("--api", help="URL base (WebUI o ComfyUI según backend)")
    args = parser.parse_args()

    cfg = load_config()
    settings = cfg["settings"]
    categories = cfg["categories"]
    backend = settings.get("backend", "webui").lower()

    if args.ids:
        wanted = {x.strip() for x in args.ids.split(",") if x.strip()}
        categories = [c for c in categories if c["id"] in wanted]
        if not categories:
            raise SystemExit(f"Ningún ID válido en: {args.ids}")

    out_dir = ROOT / settings["output_dir"]
    out_dir.mkdir(parents=True, exist_ok=True)

    print(f"Categorías a generar: {len(categories)}")
    print(f"Backend: {backend}")
    print(f"Modelo: {settings['model']}")
    print(f"Salida: {out_dir}\n")

    if args.dry_run:
        for cat in categories:
            prompt = f"{settings['style_prefix']}, {cat['scene']}"
            print(f"[{cat['id']}] {cat['label']}")
            print(f"  PROMPT: {prompt}\n")
        return

    if backend == "comfyui":
        api_base = (args.api or settings.get("comfyui", {}).get("api", COMFY_API)).rstrip("/")
        verify_comfy_model(settings)
        generate_fn = lambda cat, seed: generate_comfyui(api_base, cat, settings, seed)
    else:
        api_base = (args.api or SD_API).rstrip("/")
        wait_for_webui(api_base)
        set_webui_model(api_base, settings["model"], settings)
        generate_fn = lambda cat, seed: generate_webui(api_base, cat, settings)

    ok, fail = 0, 0
    base_seed = int(time.time()) % 1_000_000
    for i, cat in enumerate(categories, 1):
        dest = out_dir / f"{cat['id']}.png"
        if dest.exists() and not args.force:
            if dest.stat().st_size >= MIN_BYTES and is_valid_image(dest.read_bytes()):
                print(f"[{i}/{len(categories)}] {cat['id']} — ya existe, omitiendo")
                ok += 1
                continue
            print(f"[{i}/{len(categories)}] {cat['id']} — archivo inválido, regenerando…")
        else:
            print(f"[{i}/{len(categories)}] Generando {cat['id']} ({cat['label']})…")
        try:
            raw = generate_fn(cat, base_seed + i)
            dest.write_bytes(raw)
            print(f"  ✓ {dest.name} ({len(raw) // 1024} KB)")
            ok += 1
        except Exception as e:
            print(f"  ✗ Error: {e}")
            fail += 1

    print(f"\nListo: {ok} ok, {fail} fallidas.")
    if ok:
        print("Recompila la app: flutter clean && flutter run -d emulator-5554")


if __name__ == "__main__":
    main()
