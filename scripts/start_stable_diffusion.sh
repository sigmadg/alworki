#!/usr/bin/env bash
# Inicia AUTOMATIC1111 Stable Diffusion WebUI con API habilitada.
set -euo pipefail

SD_ROOT="${SD_WEBUI_ROOT:-$HOME/stable-diffusion-webui-master/stable-diffusion-webui}"
PORT="${SD_PORT:-7860}"

if [[ ! -f "$SD_ROOT/webui.sh" ]]; then
  echo "No se encontró webui.sh en: $SD_ROOT"
  echo "Define SD_WEBUI_ROOT si está en otra ruta."
  exit 1
fi

export COMMANDLINE_ARGS="--api --port $PORT --xformers --medvram --no-half-vae"

# Evitar que un venv ajeno (p.ej. Backend) secuestre el Python de WebUI
if [[ -n "${VIRTUAL_ENV:-}" ]]; then
  echo "Desactivando venv externo: $VIRTUAL_ENV"
  deactivate 2>/dev/null || true
  unset VIRTUAL_ENV
  PATH=$(echo ":$PATH:" | tr ':' '\n' | grep -v '/venv/bin' | grep -v '/.venv/bin' | paste -sd: -)
  export PATH
fi

echo "Iniciando Stable Diffusion WebUI en http://127.0.0.1:$PORT"
echo "API: http://127.0.0.1:$PORT/sdapi/v1/txt2img"
cd "$SD_ROOT"
exec ./webui.sh "$@"
