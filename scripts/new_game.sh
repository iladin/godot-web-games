#!/usr/bin/env bash
# Scaffold a new game from template/.
# Usage: ./scripts/new_game.sh <slug> "<Title>"
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
slug="${1:-}"
title="${2:-}"

if [[ ! "$slug" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
  echo "usage: $0 <slug: lowercase-kebab> \"<Title>\"" >&2
  exit 1
fi
[[ -n "$title" ]] || title="$(echo "$slug" | tr '-' ' ' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1')"

dest="$ROOT/games/$slug"
if [[ -e "$dest" ]]; then
  echo "games/$slug already exists" >&2
  exit 1
fi

cp -r "$ROOT/template" "$dest"

# Escape for sed replacement, and for embedding inside JSON / GDScript strings.
safe_title="$(printf '%s' "$title" | sed -e 's/[\\"]/\\&/g')"
sed_title="$(printf '%s' "$safe_title" | sed -e 's/[\\&|]/\\&/g')"
grep -rl "__TITLE__" "$dest" | while read -r f; do
  # No -i suffix: avoids creating .bak files that sandboxed folders can't delete.
  sed -i "s|__TITLE__|$sed_title|g" "$f"
done

echo "Created games/$slug  (\"$title\")"
echo "Next: write games/$slug/DESIGN.md, build in games/$slug/scripts/, then ./scripts/check.sh $slug"
