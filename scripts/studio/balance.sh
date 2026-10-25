#!/usr/bin/env bash
# Headless simulation telemetry for balance work.
# Usage: bash scripts/studio/balance.sh <slug> [minutes=30] [seeds=3] [policy=passive|economic]
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SLUG="$1"; MIN="${2:-30}"; SEEDS="${3:-3}"; POLICY="${4:-passive}"
GODOT="${GODOT:-$(bash "$ROOT/scripts/studio/ensure_godot.sh" | tail -1)}"
TOOL="res://scripts/tools/balance.gd"
[[ -f "$ROOT/games/$SLUG/scripts/tools/balance.gd" ]] || { echo "no balance harness in games/$SLUG/scripts/tools/balance.gd"; exit 1; }
"$GODOT" --headless --path "$ROOT/games/$SLUG" --script "$TOOL" -- --minutes="$MIN" --seeds="$SEEDS" --policy="$POLICY" 2>&1 \
  | grep -E "^BALANCE_|SCRIPT ERROR|Parse Error|Invalid"
