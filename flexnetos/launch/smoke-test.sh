#!/usr/bin/env bash
# FlexNetOS smoke test for the run-in-place install.
#
# Launches AionUi in --webui mode through flexnetos/launch/run-in-place.sh,
# polls .aionui-data/ for evidence of Electron-managed userData artifacts,
# then kills the process and reports.
#
# Used by:
#   - flexnetos/docs/INSTALL_PROOF.md → "How to re-run this verification"
#   - any CI / local job validating contract check #7
#
# Usage:
#   flexnetos/launch/smoke-test.sh                  # default 180s timeout
#   SMOKE_TIMEOUT_S=300 flexnetos/launch/smoke-test.sh
#
# Output:
#   $PROOF_DIR/smoke.log         electron-vite + electron stdout/stderr
#   $PROOF_DIR/smoke.pid         pgid we launched
#   exit 0 on success, 1 on timeout, 2 on launch failure

set -u

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DATA="$REPO_ROOT/.aionui-data"
PROOF_DIR="${PROOF_DIR:-${TMPDIR:-/tmp}/aionui-proof}"
TIMEOUT_S="${SMOKE_TIMEOUT_S:-180}"
POLL_S="${SMOKE_POLL_S:-2}"

mkdir -p "$PROOF_DIR"
LOG="$PROOF_DIR/smoke.log"
PIDFILE="$PROOF_DIR/smoke.pid"

cd "$REPO_ROOT"

if [[ ! -x "$SCRIPT_DIR/run-in-place.sh" ]]; then
  echo "error: $SCRIPT_DIR/run-in-place.sh is missing or not executable" >&2
  exit 2
fi

pkill -f 'electron-vite dev -- --webui' 2>/dev/null || true
sleep 1

echo "[smoke] repo:      $REPO_ROOT"
echo "[smoke] proof dir: $PROOF_DIR"
echo "[smoke] launching: flexnetos/launch/run-in-place.sh --webui"
echo "[smoke] log:       $LOG"
echo "[smoke] timeout:   ${TIMEOUT_S}s"

setsid bash "$SCRIPT_DIR/run-in-place.sh" --webui >"$LOG" 2>&1 &
PGID=$!
echo "$PGID" >"$PIDFILE"

CHECK_FOR="AionUi|Local Storage|IndexedDB|GPUCache|Preferences|Cookies"
START=$SECONDS
WROTE=""
while (( SECONDS - START < TIMEOUT_S )); do
  if find "$DATA" -mindepth 1 -maxdepth 4 \
       -not -path '*/mcp-servers*' -not -path '*/agents*' \
       -not -name '.gitignore' -not -name 'README.md' 2>/dev/null \
       | grep -E "$CHECK_FOR" >/dev/null; then
    WROTE=yes
    break
  fi
  sleep "$POLL_S"
done

ELAPSED=$((SECONDS - START))
echo "[smoke] elapsed:   ${ELAPSED}s"
echo "[smoke] wrote?:    ${WROTE:-no}"

if [[ -s "$PIDFILE" ]]; then
  KILL_PGID="$(cat "$PIDFILE")"
  echo "[smoke] killing pgid $KILL_PGID"
  kill -INT  -- "-$KILL_PGID" 2>/dev/null || true
  sleep 3
  kill -TERM -- "-$KILL_PGID" 2>/dev/null || true
  sleep 1
  kill -KILL -- "-$KILL_PGID" 2>/dev/null || true
fi
pkill -f 'electron-vite dev -- --webui' 2>/dev/null || true
pkill -f 'electron .*--webui' 2>/dev/null || true

echo
echo "=== POST .aionui-data/ tree (top-level only) ==="
find "$DATA" -mindepth 1 -maxdepth 2 \
  -not -path '*/mcp-servers/*' -not -path '*/agents/*' 2>/dev/null | sort

[[ -n "$WROTE" ]] && exit 0 || exit 1
