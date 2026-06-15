#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." >/dev/null && pwd -P)"
  TEST_ROOT="$(mktemp -d)"
  TEST_LOG_DIR="$TEST_ROOT/logs"
  TEST_STATE_DIR="$TEST_ROOT/state"
  export TEST_LOG_DIR

  mkdir -p "$TEST_ROOT/bin" "$TEST_ROOT/dictation/bin" "$TEST_ROOT/dictation/scripts" "$TEST_ROOT/stubs" "$TEST_LOG_DIR" "$TEST_STATE_DIR"
  cp "$REPO_ROOT/bin/local-dictation" "$TEST_ROOT/bin/local-dictation"
  cp "$REPO_ROOT/bin/select-mic" "$TEST_ROOT/bin/select-mic"
  cp "$REPO_ROOT/dictation/bin/local-dictation" "$TEST_ROOT/dictation/bin/local-dictation"
  cp "$REPO_ROOT"/dictation/scripts/*.sh "$TEST_ROOT/dictation/scripts/"
  chmod 755 "$TEST_ROOT/bin/local-dictation" "$TEST_ROOT/bin/select-mic" "$TEST_ROOT/dictation/bin/local-dictation" "$TEST_ROOT"/dictation/scripts/*.sh

  create_stubs
  touch "$TEST_ROOT/model.bin"
  touch "$TEST_ROOT/vad.bin"
  rewrite_config 'AUTO_PASTE="false"' 'CLEANUP="true"'
}

teardown() {
  if [[ -f "$TEST_STATE_DIR/recording.pid" ]]; then
    pid="$(<"$TEST_STATE_DIR/recording.pid")"
    if [[ "$pid" =~ ^[0-9]+$ ]]; then
      kill "$pid" >/dev/null 2>&1 || true
    fi
  fi

  rm -rf "$TEST_ROOT"
}

create_stubs() {
  cat >"$TEST_ROOT/stubs/ffmpeg" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "$*" >>"$TEST_LOG_DIR/ffmpeg.args"
audio_file="${@: -1}"
if [[ -z "${TEST_FFMPEG_DELAY_AUDIO:-}" ]]; then
  printf 'dummy audio\n' >"$audio_file"
fi

finish() {
  printf 'dummy audio\n' >"$audio_file"
  exit 0
}

trap finish INT TERM
while true; do
  sleep 10 &
  wait "$!" || true
done
STUB

  cat >"$TEST_ROOT/stubs/whisper-cli" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "$*" >>"$TEST_LOG_DIR/whisper.args"
printf 'whisper_full_with_state: auto-detected language: %s (p = 0.900000)\n' "${TEST_WHISPER_LANGUAGE:-ja}"
out_prefix=""
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -of)
      out_prefix="$2"
      shift 2
      ;;
    -h | --help)
      printf '%s\n' '             --carry-initial-prompt [false  ] always prepend initial prompt'
      exit 0
      ;;
    *)
      shift
      ;;
  esac
done

if [[ -n "${TEST_WHISPER_SILENCE_TEXT:-}" ]]; then
  printf '%s' "$TEST_WHISPER_SILENCE_TEXT" >"${out_prefix}.txt"
elif [[ -n "${TEST_WHISPER_JAPANESE_TEXT:-}" ]]; then
  printf '%s' "$TEST_WHISPER_JAPANESE_TEXT" >"${out_prefix}.txt"
else
  printf '  テスト音声です  \n' >"${out_prefix}.txt"
fi
STUB

  cat >"$TEST_ROOT/stubs/afplay" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail

basename "$1" >>"$TEST_LOG_DIR/sounds.log"
STUB

cat >"$TEST_ROOT/stubs/pbcopy" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail

{
  printf 'LANG=%s\n' "${LANG:-}"
  printf 'LC_ALL=%s\n' "${LC_ALL:-}"
  printf 'LC_CTYPE=%s\n' "${LC_CTYPE:-}"
} >"$TEST_LOG_DIR/pbcopy.env"
cat >"$TEST_LOG_DIR/clipboard.txt"
STUB

  cat >"$TEST_ROOT/stubs/osascript" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "$*" >>"$TEST_LOG_DIR/osascript.args"
STUB

  cat >"$TEST_ROOT/stubs/SwitchAudioSource" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "$*" >>"$TEST_LOG_DIR/SwitchAudioSource.args"

type=""
format=""
mode=""
selected=""
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -a | -c)
      mode="$1"
      shift
      ;;
    -t)
      type="$2"
      shift 2
      ;;
    -f)
      format="$2"
      shift 2
      ;;
    -s)
      selected="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

if [[ "$type" != "input" ]]; then
  printf 'unexpected type: %s\n' "$type" >&2
  exit 2
fi

if [[ -n "$selected" ]]; then
  printf '%s\n' "$selected" >>"$TEST_LOG_DIR/selected-mic.txt"
  exit 0
fi

if [[ "$format" != "json" ]]; then
  printf 'unexpected format: %s\n' "$format" >&2
  exit 2
fi

case "$mode" in
  -a)
    printf '{"name": "MacBook Pro Microphone", "type": "input", "id": "107", "uid": "BuiltInMicrophoneDevice"}\n'
    printf '{"name": "AirPods Pro", "type": "input", "id": "169", "uid": "AirPodsProDevice"}\n'
    printf '{"name": "USB Microphone", "type": "input", "id": "188", "uid": "USBMicrophoneDevice"}\n'
    ;;
  -c)
    if [[ -f "$TEST_LOG_DIR/selected-mic.txt" ]]; then
      current="$(tail -n 1 "$TEST_LOG_DIR/selected-mic.txt")"
      printf '{"name": "%s", "type": "input", "id": "169", "uid": "SelectedDevice"}\n' "$current"
      exit 0
    fi
    printf '{"name": "%s", "type": "input", "id": "107", "uid": "CurrentDevice"}\n' "${TEST_CURRENT_MIC:-MacBook Pro Microphone}"
    ;;
  *)
    printf 'unexpected mode: %s\n' "$mode" >&2
    exit 2
    ;;
esac
STUB

  cat >"$TEST_ROOT/stubs/jq" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail

while [[ "$#" -gt 0 ]]; do
  shift
done

sed -n 's/.*"name": "\([^"]*\)".*/\1/p'
STUB

  cat >"$TEST_ROOT/stubs/peco" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail

cat >"$TEST_LOG_DIR/peco-input.txt"

if [[ -n "${TEST_PECO_CANCEL:-}" ]]; then
  exit 1
fi

printf '%s\n' "${TEST_PECO_SELECTION:-AirPods Pro}"
STUB

  chmod 755 "$TEST_ROOT"/stubs/*
}

wait_for_file_contains() {
  local file="$1"
  local expected="$2"

  for _ in {1..50}; do
    if [[ -f "$file" ]] && grep -Fq -- "$expected" "$file"; then
      return 0
    fi
    sleep 0.1
  done

  return 1
}

rewrite_config() {
  local auto_paste="$1"
  local cleanup="$2"

  cat >"$TEST_ROOT/dictation/scripts/config.sh" <<CONFIG
#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2034

DICTATION_STATE_DIR="$TEST_STATE_DIR"
PID_FILE="\$DICTATION_STATE_DIR/recording.pid"
LOCK_DIR="\$DICTATION_STATE_DIR/lock"
AUDIO_FILE="\$DICTATION_STATE_DIR/dictation.wav"
TXT_PREFIX="\$DICTATION_STATE_DIR/dictation"
TXT_FILE="\$TXT_PREFIX.txt"

APP_LOG="\$DICTATION_STATE_DIR/dictation.log"
FFMPEG_LOG="\$DICTATION_STATE_DIR/ffmpeg.log"
WHISPER_LOG="\$DICTATION_STATE_DIR/whisper.log"
SOUND_LOG="\$DICTATION_STATE_DIR/sound.log"

FFMPEG_BIN="$TEST_ROOT/stubs/ffmpeg"
WHISPER_BIN="$TEST_ROOT/stubs/whisper-cli"
AFPLAY_BIN="$TEST_ROOT/stubs/afplay"
PBCOPY_BIN="$TEST_ROOT/stubs/pbcopy"
OSASCRIPT_BIN="$TEST_ROOT/stubs/osascript"

MODEL_PATH="$TEST_ROOT/model.bin"
VAD_MODEL_PATH="$TEST_ROOT/vad.bin"
MIC_DEVICE=":default"
WHISPER_LANGUAGE="auto"
WHISPER_ALLOWED_LANGUAGES="ja en"
WHISPER_PROMPT="日英混在 transcript: local dictation, Right Control, clipboard, whisper.cpp, ffmpeg, Hammerspoon, Karabiner, AirPods Pro."
WHISPER_MAX_CONTEXT="64"
WHISPER_TEMPERATURE="0"
WHISPER_TEMPERATURE_INC="0"
WHISPER_NO_FALLBACK="true"
WHISPER_SUPPRESS_NST="true"
WHISPER_CARRY_INITIAL_PROMPT="true"
WHISPER_USE_VAD="false"
$auto_paste
$cleanup

START_SOUND="/System/Library/Sounds/Pop.aiff"
STOP_SOUND="/System/Library/Sounds/Glass.aiff"
DONE_SOUND="/System/Library/Sounds/Hero.aiff"
ERROR_SOUND="/System/Library/Sounds/Basso.aiff"
CONFIG
}

@test "準正常系: 現在の入力マイクが一覧で選択状態として表示される" {
  run env PATH="$TEST_ROOT/stubs:/usr/bin:/bin" \
    TEST_CURRENT_MIC="MacBook Pro Microphone" \
    TEST_PECO_SELECTION="MacBook Pro Microphone" \
    "$TEST_ROOT/bin/select-mic"

  [ "$status" -eq 0 ]
  grep -Fxq "* MacBook Pro Microphone" "$TEST_LOG_DIR/peco-input.txt"
  grep -Fxq "  AirPods Pro" "$TEST_LOG_DIR/peco-input.txt"
  grep -Fxq "  USB Microphone" "$TEST_LOG_DIR/peco-input.txt"
  grep -Fxq "MacBook Pro Microphone" "$TEST_LOG_DIR/selected-mic.txt"
}

@test "準正常系: 古い録音状態が残っているとき新しい録音を開始できる" {
  mkdir -p "$TEST_STATE_DIR"
  printf '999999\n' >"$TEST_STATE_DIR/recording.pid"

  run "$TEST_ROOT/bin/local-dictation" toggle

  [ "$status" -eq 0 ]
  [[ -f "$TEST_STATE_DIR/recording.pid" ]]
  wait_for_file_contains "$TEST_LOG_DIR/ffmpeg.args" ":default"
  wait_for_file_contains "$TEST_LOG_DIR/ffmpeg.args" "-nostdin"
  wait_for_file_contains "$TEST_LOG_DIR/sounds.log" "Pop.aiff"
}

@test "準正常系: 録音ファイルの作成が遅いとき録音開始を続行できる" {
  export TEST_FFMPEG_DELAY_AUDIO="true"

  run "$TEST_ROOT/bin/local-dictation" start

  [ "$status" -eq 0 ]
  [[ -f "$TEST_STATE_DIR/recording.pid" ]]
  wait_for_file_contains "$TEST_STATE_DIR/dictation.log" "audio file not created yet after ffmpeg start"
  wait_for_file_contains "$TEST_LOG_DIR/sounds.log" "Pop.aiff"
}

@test "準正常系: 別のトグル処理中は新しいトグルを無視する" {
  mkdir -p "$TEST_STATE_DIR/lock"

  run "$TEST_ROOT/bin/local-dictation" toggle

  [ "$status" -eq 0 ]
  [[ ! -f "$TEST_STATE_DIR/recording.pid" ]]
  [[ ! -f "$TEST_LOG_DIR/ffmpeg.args" ]]
}

@test "準正常系: 冒頭の発話を落とさないためVAD付きで文字起こしされる" {
  rewrite_config 'AUTO_PASTE="false"' $'CLEANUP="true"\nWHISPER_USE_VAD="true"'
  printf 'dummy audio\n' >"$TEST_STATE_DIR/dictation.wav"

  run "$TEST_ROOT/bin/local-dictation" transcribe

  [ "$status" -eq 0 ]
  grep -Fq -- "--vad" "$TEST_LOG_DIR/whisper.args"
  grep -Fq -- "-vm $TEST_ROOT/vad.bin" "$TEST_LOG_DIR/whisper.args"
  grep -Fq -- "-l auto" "$TEST_LOG_DIR/whisper.args"
}

@test "準正常系: 日本語と英語が混ざるとき混在用の設定で文字起こしされる" {
  printf 'dummy audio\n' >"$TEST_STATE_DIR/dictation.wav"

  run "$TEST_ROOT/bin/local-dictation" transcribe

  [ "$status" -eq 0 ]
  grep -Fq -- "--prompt 日英混在 transcript: local dictation, Right Control, clipboard, whisper.cpp, ffmpeg, Hammerspoon, Karabiner, AirPods Pro." "$TEST_LOG_DIR/whisper.args"
  grep -Fq -- "--carry-initial-prompt" "$TEST_LOG_DIR/whisper.args"
  grep -Fq -- "-mc 64" "$TEST_LOG_DIR/whisper.args"
  grep -Fq -- "-tp 0" "$TEST_LOG_DIR/whisper.args"
  grep -Fq -- "-tpi 0" "$TEST_LOG_DIR/whisper.args"
  grep -Fq -- "-nf" "$TEST_LOG_DIR/whisper.args"
  grep -Fq -- "-sns" "$TEST_LOG_DIR/whisper.args"
  if grep -Fq -- "--vad" "$TEST_LOG_DIR/whisper.args"; then
    return 1
  fi
}

@test "準正常系: 冒頭に無音ラベルがあるとき発話だけがクリップボードに入る" {
  # shellcheck disable=SC2030
  export TEST_WHISPER_SILENCE_TEXT=$'[音声なし]\nHi, can you hear me?\n'
  printf 'dummy audio\n' >"$TEST_STATE_DIR/dictation.wav"

  run "$TEST_ROOT/bin/local-dictation" transcribe

  [ "$status" -eq 0 ]
  [ "$(cat "$TEST_LOG_DIR/clipboard.txt")" = "Hi, can you hear me?" ]
}

@test "準正常系: 同じ認識結果が連続するとき重複を除いてコピーされる" {
  # shellcheck disable=SC2030,SC2031
  export TEST_WHISPER_SILENCE_TEXT=$'日本語と英語を一言で混ぜることができますか?\n日本語と英語を一言で混ぜることができますか?\n例えば、local dictation を test します。\n'
  printf 'dummy audio\n' >"$TEST_STATE_DIR/dictation.wav"

  run "$TEST_ROOT/bin/local-dictation" transcribe

  [ "$status" -eq 0 ]
  [ "$(cat "$TEST_LOG_DIR/clipboard.txt")" = $'日本語と英語を一言で混ぜることができますか?\n例えば、local dictation を test します。' ]
}

@test "準正常系: 既知の字幕由来テキストが出たとき発話だけがコピーされる" {
  # shellcheck disable=SC2030,SC2031
  export TEST_WHISPER_SILENCE_TEXT=$'Undertexter av Amara.org-gemenskapen\nClick the link in the description below if you want to subscribe to my channel and get notified of my new videos.\nThank you so much for watching until the end, and I will see you in the next video.\n実際の発話です。\n'
  printf 'dummy audio\n' >"$TEST_STATE_DIR/dictation.wav"

  run "$TEST_ROOT/bin/local-dictation" transcribe

  [ "$status" -eq 0 ]
  [ "$(cat "$TEST_LOG_DIR/clipboard.txt")" = "実際の発話です。" ]
}

@test "正常系: プロンプト内の語彙を話したときそのままコピーされる" {
  # shellcheck disable=SC2030
  export TEST_WHISPER_JAPANESE_TEXT=$'local dictation, Right Control, clipboard, whisper.cpp を設定します。\n'
  printf 'dummy audio\n' >"$TEST_STATE_DIR/dictation.wav"

  run "$TEST_ROOT/bin/local-dictation" transcribe

  [ "$status" -eq 0 ]
  [ "$(cat "$TEST_LOG_DIR/clipboard.txt")" = "local dictation, Right Control, clipboard, whisper.cpp を設定します。" ]
}

@test "正常系: 選択した入力マイクをmacOSのデフォルト入力に設定できる" {
  run env PATH="$TEST_ROOT/stubs:/usr/bin:/bin" \
    TEST_CURRENT_MIC="MacBook Pro Microphone" \
    TEST_PECO_SELECTION="  AirPods Pro" \
    "$TEST_ROOT/bin/select-mic"

  [ "$status" -eq 0 ]
  grep -Fxq "AirPods Pro" "$TEST_LOG_DIR/selected-mic.txt"
  [[ "$output" == "AirPods Pro" ]]
  grep -Fxq -- "-a -t input -f json" "$TEST_LOG_DIR/SwitchAudioSource.args"
  grep -Fxq -- "-c -t input -f json" "$TEST_LOG_DIR/SwitchAudioSource.args"
}

@test "正常系: dictationはmacOS default inputを録音入力として使う" {
  run "$TEST_ROOT/bin/local-dictation" start

  [ "$status" -eq 0 ]
  wait_for_file_contains "$TEST_LOG_DIR/ffmpeg.args" ":default"
}

@test "正常系: 録音開始から停止まで行うと文字起こし結果がクリップボードに入る" {
  run "$TEST_ROOT/bin/local-dictation" toggle
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/bin/local-dictation" toggle

  [ "$status" -eq 0 ]
  [ "$(cat "$TEST_LOG_DIR/clipboard.txt")" = "テスト音声です" ]
  wait_for_file_contains "$TEST_LOG_DIR/sounds.log" "Pop.aiff"
  wait_for_file_contains "$TEST_LOG_DIR/sounds.log" "Glass.aiff"
  wait_for_file_contains "$TEST_LOG_DIR/sounds.log" "Hero.aiff"
  [[ ! -e "$TEST_STATE_DIR/dictation.wav" ]]
  [[ ! -e "$TEST_STATE_DIR/dictation.txt" ]]
}

@test "正常系: 日本語をコピーするときUTF-8ロケールでpbcopyが実行される" {
  # shellcheck disable=SC2031
  export TEST_WHISPER_JAPANESE_TEXT=$'日本語とEnglish\n'
  printf 'dummy audio\n' >"$TEST_STATE_DIR/dictation.wav"

  run "$TEST_ROOT/bin/local-dictation" transcribe

  [ "$status" -eq 0 ]
  [ "$(cat "$TEST_LOG_DIR/clipboard.txt")" = "日本語とEnglish" ]
  grep -Fxq "LANG=ja_JP.UTF-8" "$TEST_LOG_DIR/pbcopy.env"
  grep -Fxq "LC_ALL=ja_JP.UTF-8" "$TEST_LOG_DIR/pbcopy.env"
  grep -Fxq "LC_CTYPE=ja_JP.UTF-8" "$TEST_LOG_DIR/pbcopy.env"
}

@test "正常系: 自動ペーストが有効なとき貼り付け操作が実行される" {
  rewrite_config 'AUTO_PASTE="true"' 'CLEANUP="true"'

  run "$TEST_ROOT/bin/local-dictation" start
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/bin/local-dictation" stop

  [ "$status" -eq 0 ]
  [[ "$(cat "$TEST_LOG_DIR/osascript.args")" == *"keystroke \"v\" using command down"* ]]
}

@test "異常系: モデルがないとき失敗音を鳴らして終了する" {
  printf 'dummy audio\n' >"$TEST_STATE_DIR/dictation.wav"
  rm -f "$TEST_ROOT/model.bin"

  run "$TEST_ROOT/bin/local-dictation" transcribe

  [ "$status" -ne 0 ]
  wait_for_file_contains "$TEST_LOG_DIR/sounds.log" "Basso.aiff"
  [[ ! -f "$TEST_LOG_DIR/clipboard.txt" ]]
}

@test "異常系: 想定外の言語として検出されたときクリップボードを変更しない" {
  export TEST_WHISPER_LANGUAGE="nn"
  printf 'dummy audio\n' >"$TEST_STATE_DIR/dictation.wav"

  run "$TEST_ROOT/bin/local-dictation" transcribe

  [ "$status" -ne 0 ]
  wait_for_file_contains "$TEST_LOG_DIR/sounds.log" "Basso.aiff"
  [[ ! -f "$TEST_LOG_DIR/clipboard.txt" ]]
}

@test "異常系: pecoでキャンセルするとマイクを変更しない" {
  run env PATH="$TEST_ROOT/stubs:/usr/bin:/bin" \
    TEST_PECO_CANCEL="true" \
    "$TEST_ROOT/bin/select-mic"

  [ "$status" -eq 130 ]
  [[ ! -f "$TEST_LOG_DIR/selected-mic.txt" ]]
}

@test "異常系: SwitchAudioSourceがないと失敗する" {
  mv "$TEST_ROOT/stubs/SwitchAudioSource" "$TEST_ROOT/stubs/SwitchAudioSource.disabled"

  run -127 env PATH="$TEST_ROOT/stubs:/bin" "$TEST_ROOT/bin/select-mic"

  [ "$status" -eq 127 ]
  [[ "$output" == *"SwitchAudioSource not found"* ]]
  [[ ! -f "$TEST_LOG_DIR/selected-mic.txt" ]]
}

@test "異常系: pecoがないと失敗する" {
  mv "$TEST_ROOT/stubs/peco" "$TEST_ROOT/stubs/peco.disabled"

  run -127 env PATH="$TEST_ROOT/stubs:/usr/bin:/bin" "$TEST_ROOT/bin/select-mic"

  [ "$status" -eq 127 ]
  [[ "$output" == *"peco not found"* ]]
  [[ ! -f "$TEST_LOG_DIR/selected-mic.txt" ]]
}

@test "異常系: jqがないと失敗する" {
  mv "$TEST_ROOT/stubs/jq" "$TEST_ROOT/stubs/jq.disabled"

  run -127 env PATH="$TEST_ROOT/stubs:/bin" "$TEST_ROOT/bin/select-mic"

  [ "$status" -eq 127 ]
  [[ "$output" == *"jq not found"* ]]
  [[ ! -f "$TEST_LOG_DIR/selected-mic.txt" ]]
}

@test "異常系: 不明なサブコマンドのとき使い方を表示して失敗する" {
  run "$TEST_ROOT/bin/local-dictation" unknown

  [ "$status" -eq 2 ]
  [[ "$output" == *"usage:"* ]]
}
