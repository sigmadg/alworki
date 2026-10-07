#!/usr/bin/env bash
# Arranca la API Flask en :5002 si aún no está activa. Idempotente.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BACKEND="$ROOT/Backend"
PID_FILE="$BACKEND/.alworki-api.pid"
PORT="${ALWORKI_API_PORT:-5002}"
HEALTH_URL="http://127.0.0.1:${PORT}/health"

health_ok() {
  curl -sf --max-time 2 "$HEALTH_URL" >/dev/null 2>&1
}

if health_ok; then
  echo "API ya activa en :${PORT}"
  exit 0
fi

cd "$BACKEND"
if [[ -f "$BACKEND/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$BACKEND/.env"
  set +a
elif [[ -f "$ROOT/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$ROOT/.env"
  set +a
fi
if [[ ! -d venv ]]; then
  echo "Creando entorno virtual Python..."
  python3 -m venv venv
fi
# shellcheck disable=SC1091
source venv/bin/activate
pip install -q -r requirements-api.txt

echo "Iniciando API en :${PORT}..."
nohup python3 app_unified.py >/tmp/alworki-api.log 2>&1 &
echo $! >"$PID_FILE"
disown 2>/dev/null || true

for _ in $(seq 1 40); do
  if health_ok; then
    echo "API lista en ${HEALTH_URL}"
    exit 0
  fi
  sleep 0.25
done

echo "Error: la API no respondió a tiempo. Ver /tmp/alworki-api.log" >&2
exit 1
