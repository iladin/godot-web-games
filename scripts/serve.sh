#!/usr/bin/env bash
# Serve build/ locally. Single-threaded Godot exports need no special headers.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PORT="${PORT:-8000}"
[[ -d "$ROOT/build" ]] || { echo "No build/ yet — run ./scripts/export_all.sh first" >&2; exit 1; }
echo "http://localhost:$PORT"
exec python3 -m http.server "$PORT" --directory "$ROOT/build"
