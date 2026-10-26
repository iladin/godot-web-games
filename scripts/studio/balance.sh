#!/usr/bin/env bash
# Headless simulation telemetry for balance work.
# Usage: bash scripts/studio/balance.sh <slug> [minutes=30] [seeds=3] [policy=passive|economic] [first=0]
#   first = seed offset: skip the first N seeds of the harness's fixed seed list
#   (void-sovereign: 101, 118, 135, 152, 169, 186, ...). Use it to split a long run
#   under the 180 s device cap, e.g. a 6-seed 30-min economic run:
#     bash scripts/studio/balance.sh void-sovereign 30 3 economic 0
#     bash scripts/studio/balance.sh void-sovereign 30 3 economic 3
#   Each call prints its own BALANCE_SUMMARY; combine medians from the per-seed BALANCE_JSON lines.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SLUG="$1"; MIN="${2:-30}"; SEEDS="${3:-3}"; POLICY="${4:-passive}"; FIRST="${5:-0}"
GODOT="${GODOT:-$(bash "$ROOT/scripts/studio/ensure_godot.sh" | tail -1)}"
TOOL="res://scripts/tools/balance.gd"
[[ -f "$ROOT/games/$SLUG/scripts/tools/balance.gd" ]] || { echo "no balance harness in games/$SLUG/scripts/tools/balance.gd"; exit 1; }
"$GODOT" --headless --path "$ROOT/games/$SLUG" --script "$TOOL" -- --minutes="$MIN" --seeds="$SEEDS" --policy="$POLICY" --first="$FIRST" 2>&1 \
  | grep -E "^BALANCE_|SCRIPT ERROR|Parse Error|Invalid"
