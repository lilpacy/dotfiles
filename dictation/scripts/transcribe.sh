#!/usr/bin/env bash

set -euo pipefail

DICTATION_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd -P)"
# shellcheck disable=SC1091
source "$DICTATION_DIR/lib.sh"

ensure_state_dir
require_executable "$FFMPEG_BIN" "ffmpeg"
require_executable "$WHISPER_BIN" "whisper-cli"
require_executable "$PBCOPY_BIN" "pbcopy"
require_executable "$AFPLAY_BIN" "afplay"
require_file "$MODEL_PATH" "whisper model"
validate_boolean "$AUTO_PASTE" "AUTO_PASTE"
validate_boolean "$CLEANUP" "CLEANUP"
validate_boolean "$WHISPER_USE_VAD" "WHISPER_USE_VAD"
validate_boolean "$WHISPER_NO_FALLBACK" "WHISPER_NO_FALLBACK"
validate_boolean "$WHISPER_SUPPRESS_NST" "WHISPER_SUPPRESS_NST"
validate_boolean "$WHISPER_CARRY_INITIAL_PROMPT" "WHISPER_CARRY_INITIAL_PROMPT"

if [[ ! -s "$AUDIO_FILE" ]]; then
  fail "audio file is missing or empty: $AUDIO_FILE" 1
fi

: >"$WHISPER_LOG"
/bin/rm -f "$TXT_FILE"

whisper_args=(
  -m "$MODEL_PATH"
  -f "$AUDIO_FILE"
  -l "$WHISPER_LANGUAGE"
  -mc "$WHISPER_MAX_CONTEXT"
  -tp "$WHISPER_TEMPERATURE"
  -tpi "$WHISPER_TEMPERATURE_INC"
  -otxt
  -of "$TXT_PREFIX"
)

if [[ -n "$WHISPER_PROMPT" ]]; then
  whisper_args+=(--prompt "$WHISPER_PROMPT")
fi

if [[ "$WHISPER_CARRY_INITIAL_PROMPT" == "true" ]]; then
  if "$WHISPER_BIN" --help 2>&1 | /usr/bin/grep -Fq -- "--carry-initial-prompt"; then
    whisper_args+=(--carry-initial-prompt)
  else
    log "whisper-cli does not support --carry-initial-prompt"
  fi
fi

if [[ "$WHISPER_NO_FALLBACK" == "true" ]]; then
  whisper_args+=(-nf)
fi

if [[ "$WHISPER_SUPPRESS_NST" == "true" ]]; then
  whisper_args+=(-sns)
fi

if [[ "$WHISPER_USE_VAD" == "true" ]]; then
  require_file "$VAD_MODEL_PATH" "VAD model"
  whisper_args+=(--vad -vm "$VAD_MODEL_PATH")
fi

if ! "$WHISPER_BIN" "${whisper_args[@]}" >"$WHISPER_LOG" 2>&1; then
  fail "whisper-cli failed; see $WHISPER_LOG" 1
fi

if [[ "$WHISPER_LANGUAGE" == "auto" && -n "$WHISPER_ALLOWED_LANGUAGES" ]]; then
  detected_language="$(/usr/bin/sed -n 's/.*auto-detected language: \([[:alnum:]_-]*\).*/\1/p' "$WHISPER_LOG" | /usr/bin/tail -n 1)"
  if [[ -n "$detected_language" ]]; then
    case " $WHISPER_ALLOWED_LANGUAGES " in
      *" $detected_language "*)
        ;;
      *)
        fail "detected unsupported language: $detected_language" 1
        ;;
    esac
  fi
fi

if [[ ! -s "$TXT_FILE" ]]; then
  fail "transcription output is missing or empty: $TXT_FILE" 1
fi

text="$(/usr/bin/awk '
function trim(value) {
  sub(/^[[:space:]]+/, "", value)
  sub(/[[:space:]]+$/, "", value)
  return value
}

function norm(value) {
  gsub(/[[:space:]]+/, "", value)
  gsub(/[。、．，,!?！？「」『』（）()［］\[\]【】]/, "", value)
  return value
}

{
  line = trim($0)
  if (line == "") {
    next
  }
  if (line == "[音声なし]" || line == "[音声]" || line == "(音声)") {
    next
  }
  if (line ~ /^\(speaking in .*Japanese.*\)$/) {
    next
  }
  if (line ~ /^(ご視聴ありがとうございました|字幕.*ありがとうございました)$/) {
    next
  }
  if (line ~ /^(Undertexter av Amara\.org-gemenskapen)$/) {
    next
  }
  if (line ~ /^(Click the link in the description below if you want to subscribe to my channel and get notified of my new videos\.)$/) {
    next
  }
  if (line ~ /^(Thank you so much for watching until the end, and I will see you in the next video\.)$/) {
    next
  }
  normalized = norm(line)
  if (length(normalized) >= 8 && normalized == previous) {
    next
  }

  print line
  previous = normalized
}
' "$TXT_FILE")"
if [[ -z "${text//[[:space:]]/}" ]]; then
  fail "transcription text is empty after trimming" 1
fi

if ! printf '%s' "$text" | "$PBCOPY_BIN"; then
  fail "pbcopy failed" 1
fi

log "transcription copied to clipboard"
play_sound "$DONE_SOUND"

if [[ "$AUTO_PASTE" == "true" ]]; then
  require_executable "$OSASCRIPT_BIN" "osascript"
  if ! "$OSASCRIPT_BIN" -e 'tell application "System Events" to keystroke "v" using command down' >/dev/null 2>&1; then
    fail "auto paste failed" 1
  fi
fi

if [[ "$CLEANUP" == "true" ]]; then
  cleanup_outputs
fi
