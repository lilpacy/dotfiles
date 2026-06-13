#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2034

DICTATION_STATE_DIR="/tmp/local-dictation"
PID_FILE="$DICTATION_STATE_DIR/recording.pid"
LOCK_DIR="$DICTATION_STATE_DIR/lock"
AUDIO_FILE="$DICTATION_STATE_DIR/dictation.wav"
TXT_PREFIX="$DICTATION_STATE_DIR/dictation"
TXT_FILE="$TXT_PREFIX.txt"

APP_LOG="$DICTATION_STATE_DIR/dictation.log"
FFMPEG_LOG="$DICTATION_STATE_DIR/ffmpeg.log"
WHISPER_LOG="$DICTATION_STATE_DIR/whisper.log"
SOUND_LOG="$DICTATION_STATE_DIR/sound.log"

FFMPEG_BIN="/opt/homebrew/bin/ffmpeg"
WHISPER_BIN="/opt/homebrew/bin/whisper-cli"
AFPLAY_BIN="/usr/bin/afplay"
PBCOPY_BIN="/usr/bin/pbcopy"
OSASCRIPT_BIN="/usr/bin/osascript"

MODEL_PATH="$HOME/models/whisper.cpp/ggml-large-v3.bin"
VAD_MODEL_PATH="$HOME/models/whisper.cpp/ggml-silero-v6.2.0.bin"
MIC_DEVICE=":6"
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
AUTO_PASTE="false"
CLEANUP="false"

START_SOUND="/System/Library/Sounds/Pop.aiff"
STOP_SOUND="/System/Library/Sounds/Glass.aiff"
DONE_SOUND="/System/Library/Sounds/Hero.aiff"
ERROR_SOUND="/System/Library/Sounds/Basso.aiff"
