# Local Dictation

macOS ローカル音声入力。右 Control 単体押しを Karabiner-Elements で F18 に変換し、Hammerspoon から `bin/local-dictation toggle` を呼ぶ。

構成と所有権の整理は [docs/architecture.md](docs/architecture.md) に残している。

## 必要なもの

```sh
brew install whisper-cpp ffmpeg
```

`whisper-cpp` はモデルを同梱しない。日本語では `.en` ではない multilingual model を使う。

速度と精度のバランスを優先した推奨配置:

```text
~/models/whisper.cpp/ggml-medium.bin
```

モデルを別の場所に置く場合は [scripts/config.sh](scripts/config.sh) の `MODEL_PATH` を編集する。

## 設定

主な設定は [scripts/config.sh](scripts/config.sh) にある。

```sh
MODEL_PATH="$HOME/models/whisper.cpp/ggml-medium.bin"
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
```

- `MIC_DEVICE`: ffmpeg avfoundation の音声入力。環境に合わせて変更する。
- `WHISPER_LANGUAGE`: whisper.cpp の言語指定。日本語と英語を混ぜる場合は `auto` を使う。
- `WHISPER_ALLOWED_LANGUAGES`: `WHISPER_LANGUAGE="auto"` のとき、コピーを許可する検出言語。日英用途では `ja en`。
- `WHISPER_PROMPT`: 日英混在の出力形式とよく使う英語語彙を whisper.cpp に渡す initial prompt。
- `WHISPER_MAX_CONTEXT`: 反復出力を抑えるために whisper.cpp の保持文脈を制限する。既定は `64`。
- `WHISPER_TEMPERATURE` / `WHISPER_TEMPERATURE_INC`: deterministic に寄せるため既定はどちらも `0`。
- `WHISPER_NO_FALLBACK`: `true` にすると temperature fallback を止め、反復や幻覚の増幅を抑える。
- `WHISPER_SUPPRESS_NST`: `true` にすると non-speech token を抑制する。
- `WHISPER_CARRY_INITIAL_PROMPT`: `true` かつ `whisper-cli` が対応している場合、`--carry-initial-prompt` を付ける。
- `WHISPER_USE_VAD`: `true` にすると無音境界で音声区間を検出する。右 Control のトグル運用では文脈が切れて認識が悪化することがあるため、既定は `false`。
- `VAD_MODEL_PATH`: Silero VAD model の配置先。
- `AUTO_PASTE`: `true` にすると文字起こし後に Cmd+V を送る。
- `CLEANUP`: `false` にすると録音 WAV と文字起こし txt を処理後に残す。録音内容の確認が終わったら `true` に戻す。

コマンドパスは Homebrew on Apple Silicon 前提で `/opt/homebrew/bin` を使う。Intel Mac や別 prefix の場合は `FFMPEG_BIN` と `WHISPER_BIN` を編集する。

## マイクデバイス番号

確認:

```sh
ffmpeg -f avfoundation -list_devices true -i ""
```

音声デバイスの番号を見て、`scripts/config.sh` の `MIC_DEVICE` を `:0` などにする。`:` の左側は映像入力、右側が音声入力。

## Hammerspoon

[../.hammerspoon/init.lua](../.hammerspoon/init.lua) から [../.hammerspoon/modules/dictation.lua](../.hammerspoon/modules/dictation.lua) を読み込む形で追加済み。

```lua
require("modules.dictation")
```

Hammerspoon のメニューから Reload Config する。

## Karabiner-Elements

この dotfiles では `~/.config/karabiner/karabiner.json` が `/Users/lilpacy/dotfiles/.config/karabiner/karabiner.json` への symlink になっている。編集対象は [../.config/karabiner/karabiner.json](../.config/karabiner/karabiner.json)。

追加済みのルール:

```text
right_control 単体押し -> f18
right_control + 他キー -> right_control
```

この設定はKarabiner全体の設定ファイルに置く。dictation 側にルールのコピーは持たない。Karabiner-Elements 側で設定を再読み込みする。

## 使い方

```sh
bin/local-dictation toggle
bin/local-dictation start
bin/local-dictation stop
bin/local-dictation transcribe
```

通常は右 Control を 1 回押すと録音開始、もう 1 回押すと録音停止と文字起こしを行う。結果は `pbcopy` でクリップボードに入る。

## 状態音

- 録音開始: `/System/Library/Sounds/Pop.aiff`
- 録音終了: `/System/Library/Sounds/Glass.aiff`
- コピー完了: `/System/Library/Sounds/Hero.aiff`
- 失敗: `/System/Library/Sounds/Basso.aiff`

録音開始音は ffmpeg 起動後に非同期再生する。

## ログと一時ファイル

一時ファイルは `/tmp/local-dictation` に置く。

```text
/tmp/local-dictation/dictation.wav
/tmp/local-dictation/dictation.txt
/tmp/local-dictation/dictation.log
/tmp/local-dictation/ffmpeg.log
/tmp/local-dictation/whisper.log
```

`CLEANUP=false` の場合、WAV と txt は成功後も残る。録音内容には機密情報が含まれ得るため、確認が終わったら削除する。ログには文字起こし本文を保存しない。

## macOS 権限

録音にはマイク権限が必要。

Microphone の一覧に Hammerspoon が出ない場合は、まだマイクアクセスを要求していない。Hammerspoon の config を reload してから右 Control を押し、録音開始を一度試す。そこで macOS の許可ダイアログが出たら許可する。

誤って拒否した場合は、リセットしてからもう一度右 Control で録音開始する。

```sh
tccutil reset Microphone org.hammerspoon.Hammerspoon
```

Terminal から `bin/local-dictation start` を直接実行した場合は、Hammerspoon ではなく Terminal や iTerm 側にマイク権限が付くことがある。右 Control 経由で使う場合は Hammerspoon 経由で初回アクセスさせる。

`AUTO_PASTE=true` で Cmd+V を送る場合は Accessibility 権限が必要。Accessibility は手動追加できるので、一覧に Hammerspoon がなければ System Settings -> Privacy & Security -> Accessibility の `+` から Hammerspoon.app を追加する。

## トラブルシュート

`ffmpeg is not executable`:
`brew install ffmpeg` を確認し、`scripts/config.sh` の `FFMPEG_BIN` を実際のパスに合わせる。

`whisper-cli is not executable`:
`brew install whisper-cpp` を確認し、`scripts/config.sh` の `WHISPER_BIN` を実際のパスに合わせる。

`whisper model not found`:
`MODEL_PATH` に `ggml-medium.bin` などの multilingual model を配置する。

録音ファイルが空:
`ffmpeg -f avfoundation -list_devices true -i ""` で `MIC_DEVICE` を確認し、macOS のマイク権限を確認する。

右 Control で反応しない:
Karabiner-Elements が F18 を送っているか EventViewer で確認し、Hammerspoon config を reload する。
