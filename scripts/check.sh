#!/usr/bin/env bash
# Verify a game without a human: import (parse), title-screen smoke run,
# autoplay smoke run, optional selftest. Prints PASS or FAIL.
# Usage: ./scripts/check.sh <slug>      (or: all)
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-godot}"
BAD_PATTERNS='SCRIPT ERROR|Parse Error|Failed to load|Invalid call|Invalid access|Cannot call|Nonexistent function'

if ! command -v "$GODOT" >/dev/null 2>&1 && [[ ! -x "$GODOT" ]]; then
  echo "FAIL godot not found (set GODOT=/path/to/godot or run scripts/install_godot.sh)"
  exit 2
fi

run_step() { # name, dir, args...
  local name="$1" dir="$2"; shift 2
  local log
  log="$("$GODOT" --headless --path "$dir" "$@" 2>&1)"
  if grep -Eq "$BAD_PATTERNS" <<<"$log"; then
    echo "--- $name output ---"
    grep -En -B2 -A4 "$BAD_PATTERNS" <<<"$log" | head -60
    return 1
  fi
  printf '%s' "$log"
  return 0
}

check_one() {
  local slug="$1" dir="$ROOT/games/$1"
  [[ -f "$dir/project.godot" ]] || { echo "FAIL $slug: no project.godot"; return 1; }
  echo "== $slug"

  run_step import "$dir" --import >/dev/null \
    || { echo "FAIL $slug: errors during import/parse"; return 1; }

  run_step smoke "$dir" --fixed-fps 60 --quit-after 300 >/dev/null \
    || { echo "FAIL $slug: runtime errors on title screen"; return 1; }

  run_step autoplay "$dir" --fixed-fps 60 --quit-after 900 -- --autoplay >/dev/null \
    || { echo "FAIL $slug: runtime errors during autoplay"; return 1; }

  if [[ -f "$dir/scripts/selftest.gd" ]]; then
    local out
    out="$(run_step selftest "$dir" --script res://scripts/selftest.gd)" \
      || { echo "FAIL $slug: selftest errors"; return 1; }
    grep -q "SELFTEST OK" <<<"$out" || { echo "FAIL $slug: selftest did not print SELFTEST OK"; return 1; }
  fi

  echo "PASS $slug"
}

target="${1:-}"
[[ -n "$target" ]] || { echo "usage: $0 <slug>|all"; exit 1; }

status=0
if [[ "$target" == "all" ]]; then
  for p in "$ROOT"/games/*/project.godot; do
    check_one "$(basename "$(dirname "$p")")" || status=1
  done
else
  check_one "$target" || status=1
fi
[[ $status -eq 0 ]] && echo "PASS" || echo "FAIL"
exit $status
