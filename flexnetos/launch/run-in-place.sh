#!/usr/bin/env bash
# FlexNetOS run-in-place launcher for AionUi.
#
# Redirects Electron's userData to <repo>/.aionui-data/ by setting
# XDG_CONFIG_HOME before invoking electron-vite. Electron resolves userData
# under XDG_CONFIG_HOME/<app-name>/ on Linux, so this single env var moves
# the entire runtime tree into the repo without touching any upstream file.
#
# Usage:
#   flexnetos/launch/run-in-place.sh                  # dev mode (default)
#   flexnetos/launch/run-in-place.sh --webui          # web-UI mode (browser)
#   flexnetos/launch/run-in-place.sh --mode start:multi
#   flexnetos/launch/run-in-place.sh -- --some-electron-flag
#
# Environment overrides:
#   AIONUI_USER_DATA_DIR   override the userData root (default: <repo>/.aionui-data)
#                          consumed by this wrapper only; AionUi itself does not read it
#   AIONUI_BUN             path to the bun binary (default: `bun` on PATH)
#   AIONUI_RUN_SCRIPT      package.json script to invoke (default: "start")
#
set -euo pipefail

# Resolve repo root (this script lives at flexnetos/launch/run-in-place.sh).
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

RUN_SCRIPT="${AIONUI_RUN_SCRIPT:-start}"
PASSTHROUGH=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --webui)
      RUN_SCRIPT="webui"
      shift
      ;;
    --mode)
      RUN_SCRIPT="$2"
      shift 2
      ;;
    --mode=*)
      RUN_SCRIPT="${1#--mode=}"
      shift
      ;;
    --)
      shift
      PASSTHROUGH+=("$@")
      break
      ;;
    *)
      PASSTHROUGH+=("$1")
      shift
      ;;
  esac
done

USER_DATA_DIR="${AIONUI_USER_DATA_DIR:-$REPO_ROOT/.aionui-data}"
mkdir -p "$USER_DATA_DIR"

# Electron resolves userData via XDG_CONFIG_HOME/<app-name>/ on Linux.
# This is the single, authoritative redirection mechanism for this wrapper.
export XDG_CONFIG_HOME="$USER_DATA_DIR"

BUN_BIN="${AIONUI_BUN:-bun}"
if ! command -v "$BUN_BIN" >/dev/null 2>&1; then
  echo "error: bun not found on PATH (tried '$BUN_BIN')" >&2
  echo "       install bun via mise (\`mise use bun@latest\`) or set AIONUI_BUN." >&2
  exit 127
fi

cd "$REPO_ROOT"
echo "[flexnetos] repo:        $REPO_ROOT"
echo "[flexnetos] userData →   $USER_DATA_DIR"
echo "[flexnetos] script:      bun run $RUN_SCRIPT ${PASSTHROUGH[*]:-}"

if [[ ${#PASSTHROUGH[@]} -gt 0 ]]; then
  exec "$BUN_BIN" run "$RUN_SCRIPT" -- "${PASSTHROUGH[@]}"
else
  exec "$BUN_BIN" run "$RUN_SCRIPT"
fi
