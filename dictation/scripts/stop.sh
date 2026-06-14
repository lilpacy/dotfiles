#!/usr/bin/env bash

set -euo pipefail

DICTATION_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd -P)"
# shellcheck disable=SC1091
source "$DICTATION_DIR/lib.sh"

ensure_state_dir
require_executable "$AFPLAY_BIN" "afplay"

pid="$(read_pid)"
if ! is_pid_alive "$pid"; then
  remove_pid_file
  fail "recording process is not running: pid=$pid" 1
fi

if ! /bin/kill -INT "$pid" >/dev/null 2>&1; then
  fail "failed to stop recording process: pid=$pid" 1
fi

for _ in {1..50}; do
  if ! is_pid_alive "$pid"; then
    break
  fi
  /bin/sleep 0.1
done

if is_pid_alive "$pid"; then
  fail "recording process did not stop after SIGINT: pid=$pid" 1
fi

remove_pid_file
log "recording stopped: pid=$pid audio=$AUDIO_FILE"
play_sound "$STOP_SOUND"

"$DICTATION_DIR/transcribe.sh"
