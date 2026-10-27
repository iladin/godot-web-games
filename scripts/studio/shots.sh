#!/usr/bin/env bash
# Render screenshot scenarios for a game (needs xvfb-run + Mesa; works headless on Linux).
# Usage: bash scripts/studio/shots.sh <slug> <scenario>...    RES=900x720 to change resolution.
# Void Sovereign scenarios: sortie title map dock surface touch touch_surface combat over win death
# Output: .tools/shots/<slug>/<scenario>.png
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SLUG="$1"; shift
GODOT="${GODOT:-$(bash "$ROOT/scripts/studio/ensure_godot.sh" | tail -1)}"
RES="${RES:-1280x720}"
OUT="$ROOT/.tools/shots/$SLUG"
mkdir -p "$OUT"
for sc in "$@"; do
  timeout 120 xvfb-run -a -s "-screen 0 ${RES}x24" "$GODOT" --path "$ROOT/games/$SLUG" --rendering-driver opengl3 \
    --resolution "$RES" -- --shot="$sc" --shotfile="$OUT/$sc.png" 2>&1 \
    | grep -E "SCRIPT ERROR|Parse Error|Invalid call|Invalid access|Nonexistent function" | head -5
  if [[ -f "$OUT/$sc.png" ]]; then echo "shot $OUT/$sc.png"; else echo "FAILED $sc"; fi
done
