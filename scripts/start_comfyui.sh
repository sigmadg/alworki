#!/usr/bin/env bash
# Inicia ComfyUI con API para Flux/tinflux (puerto 8188).
set -euo pipefail

COMFY_ROOT="${COMFYUI_ROOT:-$HOME/ComfyUI}"
PORT="${COMFY_PORT:-8188}"

if [[ ! -f "$COMFY_ROOT/main.py" ]]; then
  echo "No se encontró ComfyUI en: $COMFY_ROOT"
  exit 1
fi

if [[ -n "${VIRTUAL_ENV:-}" ]]; then
  deactivate 2>/dev/null || true
  unset VIRTUAL_ENV
fi

echo "Iniciando ComfyUI en http://127.0.0.1:$PORT"
cd "$COMFY_ROOT"
exec ./venv/bin/python main.py --listen 127.0.0.1 --port "$PORT" --lowvram
