#!/usr/bin/env bash
# Package an exported game for itch.io (index.html at the zip root).
# Usage: ./scripts/zip_for_itch.sh <slug>
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
slug="${1:?usage: $0 <slug>}"
src="$ROOT/build/$slug"
[[ -f "$src/index.html" ]] || { echo "build/$slug missing — run ./scripts/export_all.sh" >&2; exit 1; }
mkdir -p "$ROOT/dist"
out="$ROOT/dist/$slug-web.zip"
rm -f "$out"
(cd "$src" && zip -q -r "$out" . -x game.json)
echo "$out ($(du -h "$out" | cut -f1))"
echo "itch.io: Kind of project = HTML, upload this zip, tick 'This file will be played in the browser', viewport 720x1280."
