#!/usr/bin/env bash

set -euo pipefail

DICTATION_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd -P)"
# shellcheck disable=SC1091
source "$DICTATION_DIR/config.sh"

ensure_state_dir() {
  /bin/mkdir -p "$DICTATION_STATE_DIR"
}

acquire_lock() {
  if /bin/mkdir "$LOCK_DIR" 2>/dev/null; then
    return 0
  fi

  log "dictation command already running"
  return 1
}

release_lock() {
  /bin/rmdir "$LOCK_DIR" 2>/dev/null || true
}

log() {
  ensure_state_dir
  /bin/date '+%Y-%m-%dT%H:%M:%S%z' | /usr/bin/tr -d '\n' >>"$APP_LOG"
  printf ' %s\n' "$*" >>"$APP_LOG"
}

play_sound() {
  local sound_file="$1"
  local sound_name

  if [[ ! -f "$sound_file" ]]; then
    log "sound file not found: $sound_file"
    return 1
  fi

  sound_name="$(/usr/bin/basename "$sound_file")"
  log "sound start: $sound_name"
  (
    "$AFPLAY_BIN" "$sound_file" >>"$SOUND_LOG" 2>&1
    sound_status="$?"
    log "sound finished: $sound_name status=$sound_status"
    exit "$sound_status"
  ) &
}

fail() {
  local message="$1"
  local status="$2"

  log "ERROR: $message"
  play_sound "$ERROR_SOUND" || true
  exit "$status"
}

require_executable() {
  local path="$1"
  local label="$2"

  if [[ -x "$path" ]]; then
    return 0
  fi

  fail "$label is not executable: $path" 127
}

require_file() {
  local path="$1"
  local label="$2"

  if [[ -f "$path" ]]; then
    return 0
  fi

  fail "$label not found: $path" 1
}

read_pid() {
  local pid

  if [[ ! -f "$PID_FILE" ]]; then
    fail "recording pid file not found: $PID_FILE" 1
  fi

  pid="$(<"$PID_FILE")"
  if [[ "$pid" =~ ^[0-9]+$ ]]; then
    printf '%s\n' "$pid"
    return 0
  fi

  fail "recording pid file is invalid: $PID_FILE" 1
}

is_pid_alive() {
  local pid="$1"
  /bin/kill -0 "$pid" >/dev/null 2>&1
}

remove_pid_file() {
  /bin/rm -f "$PID_FILE"
}

cleanup_outputs() {
  /bin/rm -f "$AUDIO_FILE" "$TXT_FILE"
}

validate_boolean() {
  local value="$1"
  local label="$2"

  if [[ "$value" == "true" || "$value" == "false" ]]; then
    return 0
  fi

  fail "$label must be true or false: $value" 1
}
