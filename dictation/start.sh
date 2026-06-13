#!/usr/bin/env bash

set -euo pipefail

DICTATION_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd -P)"
# shellcheck disable=SC1091
source "$DICTATION_DIR/lib.sh"

ensure_state_dir
require_executable "$FFMPEG_BIN" "ffmpeg"
require_executable "$AFPLAY_BIN" "afplay"

if [[ -f "$PID_FILE" ]]; then
  pid="$(read_pid)"
  if is_pid_alive "$pid"; then
    fail "recording is already running: pid=$pid" 1
  fi
  log "removing stale recording pid: $pid"
  remove_pid_file
fi

/bin/rm -f "$AUDIO_FILE" "$TXT_FILE"
: >"$FFMPEG_LOG"

(
  trap - INT QUIT TERM
  exec "$FFMPEG_BIN" -hide_banner -nostdin -loglevel warning -y \
    -f avfoundation -i "$MIC_DEVICE" \
    -ar 16000 -ac 1 -c:a pcm_s16le "$AUDIO_FILE"
) >>"$FFMPEG_LOG" 2>&1 &

pid="$!"
printf '%s\n' "$pid" >"$PID_FILE"

/bin/sleep 0.2
if ! is_pid_alive "$pid"; then
  remove_pid_file
  fail "ffmpeg exited immediately; see $FFMPEG_LOG" 1
fi

for _ in {1..20}; do
  if [[ -s "$AUDIO_FILE" ]]; then
    break
  fi
  /bin/sleep 0.05
done

if [[ ! -s "$AUDIO_FILE" ]]; then
  log "audio file not created yet after ffmpeg start: $AUDIO_FILE"
fi

log "recording started: pid=$pid audio=$AUDIO_FILE mic=$MIC_DEVICE"
play_sound "$START_SOUND"
