#!/usr/bin/env bash
# Removes the FlexNetOS AionUi dev launcher from the user's app menu.
# Idempotent — safe to re-run when the file doesn't exist.

set -euo pipefail

DEST_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
DEST="$DEST_DIR/flexnetos-aionui-dev.desktop"

if [[ -f "$DEST" ]]; then
  rm -f "$DEST"
  echo "[flexnetos] removed launcher  $DEST"
else
  echo "[flexnetos] launcher not installed (nothing to remove)"
fi

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$DEST_DIR" >/dev/null 2>&1 || true
fi
