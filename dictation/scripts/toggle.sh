#!/usr/bin/env bash

set -euo pipefail

DICTATION_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd -P)"
# shellcheck disable=SC1091
source "$DICTATION_DIR/lib.sh"

ensure_state_dir
if ! acquire_lock; then
  exit 0
fi
trap release_lock EXIT

if [[ ! -f "$PID_FILE" ]]; then
  "$DICTATION_DIR/start.sh"
  exit 0
fi

pid="$(read_pid)"
if is_pid_alive "$pid"; then
  "$DICTATION_DIR/stop.sh"
  exit 0
fi

log "removing stale recording pid before starting: $pid"
remove_pid_file
"$DICTATION_DIR/start.sh"
