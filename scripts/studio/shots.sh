#!/usr/bin/env bash
# Render screenshot scenarios for a game (needs xvfb-run + Mesa; works headless on Linux).
# Usage: bash scripts/studio/shots.sh <slug> <scenario>...    RES=900x720 to change resolution.
# A hung scenario is killed after SHOT_TIMEOUT seconds (default 60) and reported as FAILED.
# Void Sovereign scenarios: sortie title map dock surface touch touch_surface touch_wing dock_touch combat over win death
# Output: .tools/shots/<slug>/<scenario>.png
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SLUG="$1"; shift
GODOT="${GODOT:-$(bash "$ROOT/scripts/studio/ensure_godot.sh" | tail -1)}"
RES="${RES:-1280x720}"
OUT="$ROOT/.tools/shots/$SLUG"
mkdir -p "$OUT"
rc=0
for sc in "$@"; do
  rm -f "$OUT/$sc.png" 2>/dev/null   # best effort; where deletes are blocked the mtime check below catches stale PNGs
  start=$(date +%s)
  timeout -k 5 "${SHOT_TIMEOUT:-60}" xvfb-run -a -s "-screen 0 ${RES}x24" "$GODOT" --path "$ROOT/games/$SLUG" --rendering-driver opengl3 \
    --resolution "$RES" -- --shot="$sc" --shotfile="$OUT/$sc.png" 2>&1 \
    | grep -E "SCRIPT ERROR|Parse Error|Invalid call|Invalid access|Nonexistent function" | head -5
  if [[ -f "$OUT/$sc.png" && $(stat -c %Y "$OUT/$sc.png") -ge $start ]]; then echo "shot $OUT/$sc.png"; else echo "FAILED $sc (no fresh PNG written; stale file ignored)"; rc=1; fi
done
exit $rc
