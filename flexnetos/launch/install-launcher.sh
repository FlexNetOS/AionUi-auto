#!/usr/bin/env bash
# Installs the FlexNetOS AionUi dev launcher into the user's app menu by
# materializing a per-host copy of aionui-dev.desktop with absolute paths
# substituted into ~/.local/share/applications/. Idempotent — safe to re-run.
#
# This does NOT copy the binary anywhere. It just registers a .desktop entry
# that points at flexnetos/launch/run-in-place.sh in this clone.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

SRC="$SCRIPT_DIR/aionui-dev.desktop"
DEST_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
DEST="$DEST_DIR/flexnetos-aionui-dev.desktop"

RUN_IN_PLACE="$SCRIPT_DIR/run-in-place.sh"
ICON_PATH="$REPO_ROOT/resources/app_dev.png"
if [[ ! -f "$ICON_PATH" ]]; then
  ICON_PATH="$REPO_ROOT/resources/app.png"
fi

if [[ ! -x "$RUN_IN_PLACE" ]]; then
  chmod +x "$RUN_IN_PLACE"
fi

mkdir -p "$DEST_DIR"

sed \
  -e "s|@FLEXNETOS_RUN_IN_PLACE@|$RUN_IN_PLACE|g" \
  -e "s|@FLEXNETOS_ICON@|$ICON_PATH|g" \
  "$SRC" >"$DEST.tmp"
mv "$DEST.tmp" "$DEST"
chmod 0644 "$DEST"

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$DEST_DIR" >/dev/null 2>&1 || true
fi

echo "[flexnetos] installed launcher → $DEST"
echo "[flexnetos] exec:     $RUN_IN_PLACE"
echo "[flexnetos] icon:     $ICON_PATH"
echo "[flexnetos] uninstall: $SCRIPT_DIR/uninstall-launcher.sh"
