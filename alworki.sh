#!/usr/bin/env bash
# Arranque unificado: API Flask + app Flutter (un solo comando).
# Uso:
#   ./alworki.sh              # dispositivo por defecto
#   ./alworki.sh -d linux     # escritorio Linux
#   ./alworki.sh -d emulator-5554
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

DEVICE_ARGS=()
FLUTTER_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--device)
      DEVICE_ARGS=(-d "$2")
      shift 2
      ;;
    *)
      FLUTTER_ARGS+=("$1")
      shift
      ;;
  esac
done

echo "🚀 Alworki — backend + frontend"
"$ROOT/scripts/start_backend.sh"

resolve_api_url() {
  if [[ -n "${API_BASE_URL:-}" ]]; then
    echo "${API_BASE_URL%/}"
    return
  fi
  local target=""
  if [[ ${#DEVICE_ARGS[@]} -ge 2 ]]; then
    target="${DEVICE_ARGS[1]}"
  else
    target="$(flutter devices 2>/dev/null | awk '/•/{print $2; exit}' || true)"
  fi
  case "$target" in
    emulator-*|android*|sdk*)
      echo "http://10.0.2.2:5002"
      ;;
    *)
      echo "http://127.0.0.1:5002"
      ;;
  esac
}

API_URL="$(resolve_api_url)"
echo "📱 Flutter → API ${API_URL}"

cleanup() {
  "$ROOT/scripts/stop_backend.sh"
}
trap cleanup INT TERM EXIT

flutter run \
  "${DEVICE_ARGS[@]}" \
  --dart-define=API_BASE_URL="$API_URL" \
  --dart-define=AUTO_START_BACKEND=false \
  "${FLUTTER_ARGS[@]}"
