# Local Dictation Improvement Log

## 目的

右 Control 単体で録音を開始/停止し、macOS上で `whisper.cpp` によるローカル音声入力を行う仕組みを作った。主目的は、日本語と英語が混ざる日常ディクテーションをできるだけ破綻なく文字起こしして、結果をクリップボードに入れること。

この文書は、`dictation/docs/improve-dictation.md` のセカンドオピニオンを受けて、実際に何をどういう順番で改善したかを残すための実装記録。

## 最終状態

最終的な実装は次の2コミット。

```text
df00f53 dictation: ローカル音声入力を追加
51f9a84 dictation: トグル競合と過剰フィルタを修正
```

主な成果物。

```text
bin/local-dictation
dictation/
  bin/local-dictation
  scripts/
    config.sh
    lib.sh
    start.sh
    stop.sh
    toggle.sh
    transcribe.sh
  test/dictation.bats
  docs/improve-dictation.md
  docs/improvement-log.md
  hammerspoon.lua.example
  karabiner.json.example
  README.md
```

既存設定にも以下を追加した。

```text
.config/karabiner/karabiner.json
.hammerspoon/init.lua
.hammerspoon/modules/dictation.lua
homebrew/formula
link.sh
Makefile
```

2026-06-14時点では、速度が遅いという運用フィードバックを受けて、既定モデルを `ggml-large-v3.bin` から `ggml-medium.bin` に戻している。`large-v3` へ切り替えた判断と検証内容は履歴として後述するが、現在の `dictation/scripts/config.sh` は速度と精度のバランスを優先した medium を参照する。

## 実装前の問題

最初の実装では、録音と文字起こしは動いたが、実運用で次の問題が出た。

- `ffmpeg` で録音したWAVを `afplay` できず、WAVヘッダが壊れることがあった。
- Hammerspoon経由の `pbcopy` で日本語が文字化けした。
- `-l ja` では英語が落ちたりカタカナ化された。
- `-l en` では日本語が `(speaking in Japanese)` のような説明文になった。
- VADを有効にすると、短い発話区間に分割されて文脈が壊れ、反復が増えた。
- `large-v3` にしても、無音や壊れた録音でYouTube字幕風の幻覚が出た。
- 右 Control 連打時に複数の `toggle` が同時に走る可能性があった。
- prompt由来の断片を雑に消すと、実際に話した語彙まで落とす危険があった。

## ChatGPTの意見から採用した方針

`dictation/docs/improve-dictation.md` では、次の方針が提案された。

- 右 Control の短いトグル式ディクテーションでは、VADは既定OFFがよい。
- `large-v3` を使い、必要なら将来 `large-v2` と比較する。
- `-l auto` を本線にし、日英混在向けの initial prompt を使う。
- `-mc 64` で文脈を制限し、反復の燃料を減らす。
- `-tp 0`, `-tpi 0`, `-nf` で deterministic に寄せる。
- `-sns` で non-speech token を抑制する。
- `--carry-initial-prompt` は、使えるビルドなら付ける。
- `ffmpeg` には `-nostdin` を付ける。
- postprocessでは、連続重複行や既知の非発話テキストを除去する。
- AirPods ProはASR品質のボトルネックになり得るので、将来マイク比較をする。

このうち、本実装ではすぐ効果があり、bash構成を複雑にしすぎないものだけ採用した。

## 採用しなかったもの

次は今回は入れていない。

- `large-v2` への切り替えや自動比較
- `ja` / `en` の2-pass文字起こしと自動マージ
- 右 Control + 修飾キーによる English/Japanese 固定モード
- WhisperKit / faster-whisper への移行
- VADの調整プリセット
- timestamp付きWAVファイルの蓄積
- アプリ別の自動ペースト許可リスト

理由は、今回のゴールが「今のwhisper.cpp構成を改善してコミットすること」だったため。2-passや別ASRは設計・検証量が大きく、今の問題に対する最小の改善ではない。

## 実装手順

### 1. 録音の基本パイプラインを作った

右 ControlをKarabinerでF18に変換し、Hammerspoonから `bin/local-dictation toggle` を呼ぶ構成にした。

```text
right_control alone
  -> Karabiner: f18
  -> Hammerspoon: bin/local-dictation toggle
  -> dictation/scripts/toggle.sh
```

録音は `ffmpeg` の AVFoundation input を使う。

```bash
ffmpeg -hide_banner -nostdin -loglevel warning -y \
  -f avfoundation -i "$MIC_DEVICE" \
  -ar 16000 -ac 1 -c:a pcm_s16le "$AUDIO_FILE"
```

AirPods Pro は `ffmpeg -f avfoundation -list_devices true -i ""` の結果から `MIC_DEVICE=":6"` にした。

### 2. WAVヘッダ破損を直した

最初は録音停止後に `afplay /tmp/local-dictation/dictation.wav` が次のエラーになった。

```text
Error: AudioFileOpen failed ('wht?')
```

原因は、バックグラウンドの `ffmpeg` が非対話shellのsignal状態を引き継ぎ、`SIGINT` による正常終了ができていない可能性が高かったこと。

対策として、`start.sh` で `ffmpeg` を起動するサブシェル内で signal trap を戻した。

```bash
(
  trap - INT QUIT TERM
  exec "$FFMPEG_BIN" ...
) >>"$FFMPEG_LOG" 2>&1 &
```

その後、`stop.sh` では `kill -INT "$pid"` を送り、プロセス終了を待ってから文字起こしするようにした。

### 3. 日本語の文字化けを直した

Hammerspoon経由で `pbcopy` すると、日本語が mojibake した。

対策として、エントリポイントの `bin/local-dictation` で UTF-8 locale を固定した。

```bash
export LANG="ja_JP.UTF-8"
export LC_ALL="ja_JP.UTF-8"
export LC_CTYPE="ja_JP.UTF-8"
```

これで `pbcopy` へ流す日本語と英語混在テキストが正しくコピーされるようになった。

### 4. モデルを `large-v3` に切り替えた

精度最優先のため、`ggml-medium.bin` から `ggml-large-v3.bin` に切り替えた。

配置先。

```text
~/models/whisper.cpp/ggml-large-v3.bin
```

SHA-1確認。

```text
ad82bf6a9043ceed055076d0fd39f5f186ff8062
```

ログでも次のように `large v3` がロードされていることを確認した。

```text
whisper_model_load: type = 5 (large v3)
```

その後、日常利用では応答速度を優先したい場面が増えたため、2026-06-14に既定値を `ggml-medium.bin` へ戻した。直近の13.8秒の録音では、`ggml-medium.bin` が `type = 4 (medium)` としてロードされ、総処理時間は約3.4秒だった。

### 5. VADを既定OFFにした

VADあり/なしを同じWAVで比較した。

VADありでは、33.8秒の音声が10個のspeech segmentに分割された。

```text
whisper_vad: detected 10 speech segments
whisper_vad: Reduced audio from 540160 to 437280 samples (19.0% reduction)
```

ただし結果は悪化した。短い発話区間に分かれたことで文脈が弱くなり、日英混在・タイ語混在で反復や言い換えが増えた。

そのため、日常の右 Control トグル式では次を既定にした。

```bash
WHISPER_USE_VAD="false"
```

VAD自体はオプションとして残し、`WHISPER_USE_VAD="true"` のときだけ `--vad -vm "$VAD_MODEL_PATH"` を付ける。

### 6. 日英混在向けのwhisper設定を入れた

`dictation/docs/improve-dictation.md` の提案を受けて、`transcribe.sh` で次の引数を渡すようにした。

```bash
-l "$WHISPER_LANGUAGE"
-mc "$WHISPER_MAX_CONTEXT"
-tp "$WHISPER_TEMPERATURE"
-tpi "$WHISPER_TEMPERATURE_INC"
--prompt "$WHISPER_PROMPT"
-nf
-sns
```

既定値。

```bash
WHISPER_LANGUAGE="auto"
WHISPER_ALLOWED_LANGUAGES="ja en"
WHISPER_PROMPT="日英混在 transcript: local dictation, Right Control, clipboard, whisper.cpp, ffmpeg, Hammerspoon, Karabiner, AirPods Pro."
WHISPER_MAX_CONTEXT="64"
WHISPER_TEMPERATURE="0"
WHISPER_TEMPERATURE_INC="0"
WHISPER_NO_FALLBACK="true"
WHISPER_SUPPRESS_NST="true"
WHISPER_CARRY_INITIAL_PROMPT="true"
```

`--carry-initial-prompt` は、レビューで「ビルドによって存在しない可能性がある」と指摘された。そのため無条件には渡さず、`whisper-cli --help` に出る場合だけ追加する。

```bash
if "$WHISPER_BIN" --help 2>&1 | /usr/bin/grep -Fq -- "--carry-initial-prompt"; then
  whisper_args+=(--carry-initial-prompt)
fi
```

### 7. 想定外言語判定を失敗扱いにした

壊れた録音や長い無音で、`auto-detected language: nn` になり、YouTube字幕風の幻覚がコピーされるケースがあった。

例。

```text
Click the link in the description below...
Thank you so much for watching...
```

日英ディクテーション用途では `ja` / `en` 以外は異常の可能性が高いため、次を追加した。

```bash
WHISPER_ALLOWED_LANGUAGES="ja en"
```

`WHISPER_LANGUAGE="auto"` かつ検出言語が許可リスト外なら `fail` し、`pbcopy` しない。

実際に `nn` 判定のWAVで確認した結果。

```text
rc=1
clipboard_unchanged=yes
```

### 8. 後処理を追加した

`transcribe.sh` のawk後処理で、次を行うようにした。

- 空行を除去
- `[音声なし]`, `[音声]`, `(音声)` を除去
- `(speaking in Japanese)` 系を除去
- `ご視聴ありがとうございました` や字幕由来の既知文言を除去
- 直前行と正規化後に同じ行を除去

連続重複の例。

```text
日本語と英語を一言で混ぜることができますか?
日本語と英語を一言で混ぜることができますか?
例えば、local dictation を test します。
```

後処理後。

```text
日本語と英語を一言で混ぜることができますか?
例えば、local dictation を test します。
```

一度は prompt 内の長い断片を `index(prompt, line) > 0` で落とす実装を入れたが、レビューで「実際に話しそうな語彙まで消す」と指摘されたため削除した。代わりに、既知の字幕由来テキストだけを明示的に除去する方針にした。

### 9. 録音開始を堅牢化した

`ffmpeg` に `-nostdin` を追加した。バックグラウンド実行時にstdinへ触りに行く余地を消すため。

また、AirPods Proでは録音ファイル生成が少し遅れることがある。最初は「一定時間内にWAVが非空でないなら失敗」としたが、実機で録音開始が落ちた。

そのため、PIDが生きていれば録音開始は成功扱いにし、ファイルがまだ非空でない場合は警告ログだけ残すようにした。

```bash
if [[ ! -s "$AUDIO_FILE" ]]; then
  log "audio file not created yet after ffmpeg start: $AUDIO_FILE"
fi
```

### 10. 右 Control 連打対策を入れた

HammerspoonはF18ごとに `local-dictation toggle` を非同期起動する。そのため右 Control連打で `toggle` が並行実行されると、2つのプロセスが同時に `PID_FILE` 不在を見て `ffmpeg` を二重起動する可能性があった。

対策として、atomic `mkdir` によるロックを入れた。

```bash
LOCK_DIR="$DICTATION_STATE_DIR/lock"

acquire_lock() {
  if /bin/mkdir "$LOCK_DIR" 2>/dev/null; then
    return 0
  fi

  log "dictation command already running"
  return 1
}
```

`toggle.sh` では、処理の最初にロックを取り、終了時に解放する。

```bash
if ! acquire_lock; then
  exit 0
fi
trap release_lock EXIT
```

### 11. テストを追加した

Batsでシェルスクリプトの外形テストを作った。現在のテストは15件。

主な観点。

- 古いPIDが残っていても録音開始できる
- 録音ファイル作成が遅くても開始を続行する
- 別のtoggle処理中は新しいtoggleを無視する
- VAD有効時だけ `--vad` と `-vm` を渡す
- 日英混在向けpromptとwhisperオプションを渡す
- 無音ラベルを除去する
- 連続重複行を除去する
- 既知の字幕由来テキストを除去する
- prompt内語彙を実際に話した場合は消さずにコピーする
- UTF-8 localeで `pbcopy` される
- 自動ペーストが有効なら `osascript` を呼ぶ
- モデル欠落時は失敗音を鳴らす
- 想定外言語判定ならクリップボードを変更しない
- 不明なサブコマンドはusageを出して失敗する

実行コマンド。

```bash
make lint
make test
```

確認済みの結果。

```text
make lint: success
make test: 15 tests passed
```

### 12. コミット後レビューを行った

最初のコミット後に `codex exec` レビューを実施した。

指摘された致命点。

```text
1. toggle経路が排他されておらず、右Control連打で状態が壊れる。
2. prompt断片フィルタが強すぎて、正しい発話を捨てる。
```

対応。

- `LOCK_DIR` と `acquire_lock` / `release_lock` を追加
- `toggle.sh` にロックを追加
- prompt部分一致フィルタを削除
- 既知字幕由来テキストだけを明示的に除去
- 回帰テストを追加

追加コミット後に再レビューし、致命的指摘なしを確認した。

## 現在の運用手順

### モデル配置

```text
~/models/whisper.cpp/ggml-medium.bin
~/models/whisper.cpp/ggml-silero-v6.2.0.bin
```

### Hammerspoon

```lua
require("modules.dictation")
```

### Karabiner

```text
right_control 単体押し -> f18
right_control + 他キー -> right_control
```

### 実行

通常は右 Control を押すだけ。

手動実行。

```bash
bin/local-dictation toggle
bin/local-dictation start
bin/local-dictation stop
bin/local-dictation transcribe
```

ログ。

```text
/tmp/local-dictation/dictation.log
/tmp/local-dictation/ffmpeg.log
/tmp/local-dictation/whisper.log
/tmp/local-dictation/sound.log
```

## 残っている課題

- AirPods Pro mic と MacBook内蔵マイク、有線/USBマイクの比較。
- `large-v2` と `large-v3` の同一WAV比較。
- 英語を長く話すときの `-l en` 固定モード追加。
- 長い無音が入る録音だけに限定したVADモード。
- `CLEANUP=true` へ戻すタイミングの判断。
- 自動ペーストを使う場合のアプリ許可リスト。
- 壊れた録音や長時間無音を録音段階で検出する仕組み。

## 判断基準

今回の改善では、精度だけでなく「クリップボードを汚さないこと」を重視した。

特に、Whisperが無音や壊れた録音からもっともらしい字幕文を作ることがあるため、次の場合は成功扱いにしない。

- 文字起こし結果が空
- 後処理後に空
- `auto` の検出言語が `ja en` 以外
- モデルや録音ファイルがない
- `pbcopy` に失敗

この方針により、多少失敗音が鳴ることはあっても、誤った長文がクリップボードに入るリスクを下げた。
