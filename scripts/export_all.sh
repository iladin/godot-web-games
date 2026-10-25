#!/usr/bin/env bash
# Export every games/<slug> to build/<slug>/index.html using the "Web" preset.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-godot}"
OUT="$ROOT/build"
gh_group() { [[ -n "${GITHUB_ACTIONS:-}" ]] && echo "::group::$1" || echo "== $1"; }
gh_end()   { [[ -n "${GITHUB_ACTIONS:-}" ]] && echo "::endgroup::" || true; }

rm -rf "$OUT"
mkdir -p "$OUT"
touch "$OUT/.nojekyll"

shopt -s nullglob
count=0
for proj in "$ROOT"/games/*/project.godot; do
  dir="$(dirname "$proj")"
  slug="$(basename "$dir")"
  gh_group "Export $slug"
  mkdir -p "$OUT/$slug"
  "$GODOT" --headless --path "$dir" --import >/dev/null 2>&1 || true
  "$GODOT" --headless --path "$dir" --export-release "Web" "$OUT/$slug/index.html"
  if [[ ! -s "$OUT/$slug/index.html" || ! -s "$OUT/$slug/index.pck" ]]; then
    echo "Export failed for $slug (missing index.html / index.pck). Are the web export templates installed for this Godot version?" >&2
    exit 1
  fi
  cp "$dir/game.json" "$OUT/$slug/game.json" 2>/dev/null || true
  du -sh "$OUT/$slug"
  gh_end
  count=$((count + 1))
done

echo "Exported $count game(s) to build/"
