#!/usr/bin/env bash
# Rollback without git (git can't write on the device unless deletion is allowed).
# save:    copies games/<slug> to .tools/snapshots/<slug>/<session>/
# restore: copies it back over games/<slug> and lists files that exist now but not in the snapshot
#          (the caller should move those to games/<slug>/_to_delete/ — nothing is deleted here).
# Usage: bash scripts/studio/snapshot.sh <slug> save|restore <session-id>
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SLUG="$1"; ACTION="$2"; SID="$3"
SRC="$ROOT/games/$SLUG"
SNAP="$ROOT/.tools/snapshots/$SLUG/$SID"
case "$ACTION" in
  save)
    mkdir -p "$SNAP"
    (cd "$SRC" && find . -path ./.godot -prune -o -type f -print | while read -r f; do mkdir -p "$SNAP/$(dirname "$f")"; cp -p "$f" "$SNAP/$f"; done)
    echo "saved $SNAP" ;;
  restore)
    [[ -d "$SNAP" ]] || { echo "no snapshot $SNAP"; exit 1; }
    (cd "$SNAP" && find . -type f -print | while read -r f; do mkdir -p "$SRC/$(dirname "$f")"; cp -p "$f" "$SRC/$f"; done)
    echo "restored from $SNAP"
    (cd "$SRC" && find . -path ./.godot -prune -o -path ./_to_delete -prune -o -type f -print | while read -r f; do [[ -f "$SNAP/$f" ]] || echo "EXTRA $f"; done)
    ;;
  *) echo "usage: $0 <slug> save|restore <session-id>"; exit 2 ;;
esac
