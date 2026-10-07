#!/usr/bin/bash
# Alias de compatibilidad → arranque unificado.
exec "$(cd "$(dirname "$0")" && pwd)/alworki.sh" "$@"
