## 全体結論

今の構成は方向性としてかなり良いです。特に、`ffmpeg` を `SIGINT` で止めて WAV ヘッダを正常確定させる、16kHz mono PCM WAV にする、`large-v3` を使う、VADを一旦切る、という判断は妥当です。

一方で、いま起きている問題は単なる実装ミスではなく、Whisper 系モデルの構造的な弱点がかなり出ています。Whisper は多言語・翻訳・言語識別を同じ decoder で扱う multitask モデルで、30秒チャンク単位の処理と言語トークンに強く影響されます。OpenAI も、Whisper は多言語文字起こし、言語識別、英訳などを同じモデルで扱う設計だと説明しています。([GitHub][1])
そのため、`auto` が `ja` と判定すると decoder が「日本語の文字起こしらしい出力」に寄り、短い英語・タイ語・専門語がカタカナ化されたり、翻訳風になったりします。逆に `-l en` 固定では、日本語が英語文脈に押し込まれて `(speaking in Japanese)` のような非発話説明になりやすいです。

おすすめの基本方針は次です。

```text
日常運用:
  VADなし
  large-v3 または large-v2 比較
  -l auto
  code-switching向け initial prompt
  --suppress-nst
  -mc 64
  反復が出る場合だけ -nf / beam / entropy を段階的に試す

UX:
  右Ctrl単体 = auto mixed mode
  右Ctrl + 何か = English固定モード、Japanese固定モードを追加できると強い

録音:
  16kHz mono pcm_s16le は維持
  AirPods Pro mic は品質ボトルネック候補として必ず比較
  可能なら Mac 内蔵マイク/有線/USBマイクも同じ発話で検証
```

---

## 1. `WHISPER_USE_VAD=false` は妥当か

妥当です。少なくともあなたの用途では、デフォルトは `false` がよいです。

whisper.cpp の VAD は、先に VAD モデルで speech segment を検出し、検出された音声部分だけを Whisper に渡す仕組みです。公式 README でも、これは処理対象音声を減らして高速化し得る機能として説明されています。([GitHub][2])
ただし、あなたのログでは 33.8秒を 10 セグメントに分けています。0.54秒、0.70秒、0.92秒のような非常に短い区間もあります。この分割は、日英混在の「文脈で判断してほしい」ディクテーションには不利です。

VADありで悪化した理由はおそらくこの組み合わせです。

```text
短い発話区間に分かれる
→ 文脈が弱くなる
→ 言語判定・文脈補完が不安定になる
→ Whisper の言語モデル的な補完が強くなる
→ 反復・言い換え・幻覚が増える
```

VADを使うなら、会議録のように長い無音が多い録音向けです。右Ctrlトグル式の短いディクテーションでは、無音が数秒から十数秒も入ることは少ないはずなので、VADのメリットより境界切断のデメリットが目立ちやすいです。

どうしても試すなら、デフォルトの `vad-speech-pad-ms=30` と `vad-min-silence-duration-ms=100` はかなり細かく切れます。whisper.cpp の VAD オプションには speech padding、minimum silence duration、segment overlap などがあります。([GitHub][2])
試すならこのくらいからです。

```bash
--vad \
-vm "$VAD_MODEL_PATH" \
-vt 0.50 \
-vspd 250 \
-vsd 700 \
-vp 250 \
-vo 0.30
```

ただし、私は日常ディクテーションの本線には入れません。長い無音が多い録音だけ別モードにします。

---

## 2. `-l auto` が `ja` に寄り、英語がカタカナ化/翻訳風になる問題

whisper.cpp だけで改善はできますが、完全解決は難しいです。改善余地があるのは主に次の3つです。

### A. initial prompt を「命令」ではなく「望む文字起こし例」として入れる

OpenAI の Whisper prompting guide では、prompt は GPT の命令プロンプトとは違い、出力スタイルや綴りを寄せるための前文脈として働く、と説明されています。また、短い prompt は効きにくく、具体的な transcript 例や spelling guide が効く場合がある一方、信頼性は限定的とも説明されています。([OpenAI Developers][3])

この用途では、こういう prompt がよいです。

```bash
WHISPER_PROMPT='これは日本語と English が自然に混ざった dictation transcript です。英語で話された words and phrases は English spelling のまま残ります。今日は whisper.cpp と ffmpeg で local dictation pipeline を test します。Right Control を押して recording を start し、stop したら clipboard に copy します。Hammerspoon, Karabiner, AirPods Pro, pbcopy, initial prompt, VAD, beam size, temperature, hallucination, code-switching.'
```

ポイントは、`Do not translate` のような命令だけにしないことです。入れてもよいですが、それだけでは弱いです。Whisper に「こういう transcript が直前にあった」と見せるほうが効きます。

`--carry-initial-prompt` が使えるビルドなら、30秒を超える録音でも style bias が薄れにくくなるので有効です。ただし prompt が強すぎると、逆に実際に話していない語彙を誘導する可能性があります。

### B. `-l auto` のまま、英語語彙を prompt に入れる

たとえば技術ディクテーションなら、よく使う英語語彙を prompt に混ぜます。

```text
whisper.cpp, ffmpeg, Hammerspoon, Karabiner, right Ctrl, local dictation,
clipboard, pipeline, initial prompt, code-switching, hallucination,
VAD, beam size, temperature, entropy threshold, no fallback
```

これは「英語で話した箇所を英語表記にする」効果というより、「音響的に曖昧な語の綴り候補を English 側に寄せる」効果です。

### C. `-l ja` 固定は基本的に避ける

`-l ja` は日本語主体の文章には安定しますが、英語 phrase を英語表記で残したい目的には不利です。`-l en` は英語主体なら良いですが、日本語は説明文・英訳・欠落になりやすいので、混在モードの主設定には向きません。

---

## 3. 日英混在で英語部分を英語表記のまま残す現実解

優先順位はこうです。

### 第一候補: `-l auto` + code-switching prompt

運用の複雑さと効果のバランスが一番よいです。

```bash
-l auto \
--prompt "$WHISPER_PROMPT" \
--carry-initial-prompt \
-sns
```

`-sns / --suppress-nst` は non-speech token を抑制するオプションです。whisper.cpp の CLI help にも `--suppress-nst` と `--suppress-regex` が用意されています。([Hugging Face][4])
`(speaking in Japanese)` のような出力が出るケースでは、まず `-sns` を試す価値があります。

### 第二候補: 右Ctrl以外に「英語固定モード」を作る

現実のUXとしてはかなり強いです。

```text
右Ctrl単体        → auto mixed
右Ctrl + Shift    → English mode, -l en
右Ctrl + Option   → Japanese mode, -l ja
```

日英混在を完全自動で当てるより、「これから英語を話す」と人間が軽く示すほうが精度は上がります。特に英語 sentence が数秒以上続くなら `-l en` は有利です。

### 第三候補: 2-pass `ja` / `en` は検証用・救済用

2-pass は面白いですが、最初から本線にするには重いです。

```text
pass 1: -l auto
pass 2: -l en
後処理: en pass のほうが明らかに自然な英語 phrase だけ採用
```

ただし自動マージは難しいです。`ja` 出力と `en` 出力は segmentation も句読点も変わるので、単純 diff では壊れます。実装するなら、まずは「両方をログに残して人間が比較する」段階に留めるのがよいです。

### 第四候補: 音声区間ごとの言語判定

これは長めの英語区間には有効ですが、短い英単語には効きにくいです。

```text
「今日は local dictation pipeline を test します」
```

この中の `local dictation pipeline` だけを音声区間として切り出して英語判定するのはかなり難しいです。逆に、

```text
ここから英語で話します。Can you hear me? I am testing local dictation.
```

のように2〜3秒以上英語が続くなら、区間ごとの language detection → `-l en` 再実行は現実的です。

### Whisper派生/別ローカルASR

macOS / Apple Silicon なら、今後試す価値が高いのは WhisperKit です。WhisperKit は Homebrew で CLI を入れられ、Apple Silicon 向けの on-device ASR として large-v3 系モデルを扱えます。README では `whisperkit-cli` の Homebrew install、ローカルファイル transcription、streaming、macOS 向け model selection が説明されています。([GitHub][5])
ただし、これは Whisper 系なので、code-switching の本質的な弱点が完全に消えるわけではありません。改善候補は速度・Apple Neural Engine 活用・運用統合です。

faster-whisper は CTranslate2 ベースの Whisper 再実装で、同精度で高速・省メモリをうたっています。README では openai/whisper より最大4倍高速、量子化でさらに効率化可能と説明されています。([GitHub][6])
ただし Apple Silicon では whisper.cpp/Metal/Core ML のほうが統合しやすい場合があります。日英混在精度そのものを劇的に変えるというより、VAD・segment・confidence・Python後処理を組みやすくする選択肢です。

---

## 4. 反復出力を抑える試行順

large-v3 の反復は、whisper.cpp 側でも報告があります。whisper.cpp の issue では「large-v3 は v2 より文の反復が多いという報告が多数ある」とされています。([GitHub][7])
OpenAI Whisper 側の議論でも、無音や非発話区間で hallucination が起き、loop に入ることがある、という指摘があります。([GitHub][8])

おすすめの試行順はこれです。

### Step 0: VADなし、tail silence を減らす

VADで細切れにするより、録音末尾の長い無音だけを避けるほうが安全です。右Ctrl停止後にすぐ SIGINT しているので大きな問題ではないはずですが、停止までに1秒以上無音が入るなら末尾無音が hallucination の引き金になります。

まずは stop sound を録音後に鳴らしている点は良いです。start sound は録音開始後に鳴っているため、環境によっては音声ファイルに入ります。AirPodsなら漏れは少ないかもしれませんが、内蔵スピーカー出力ならASRにはノイズです。開始音を視覚通知にする、短い低音量音にする、または開始音後に話し始める運用にするのが安全です。

### Step 1: `-mc 64`

最初に試すべきは `--max-context` です。

```bash
-mc 64
```

反復は「前の誤出力が次の文脈として残り、そのまま増幅される」ことがあります。`-mc 64` は文脈を完全には捨てず、反復の燃料を減らせる妥協点です。

さらに反復が強ければ、

```bash
-mc 32
# または
-mc 0
```

も試します。短いディクテーションなら `-mc 0` でも実用になる可能性があります。ただし、長い発話では文脈継続が弱くなります。

### Step 2: `--suppress-nst`

```bash
-sns
```

これは非発話トークン抑制です。`(speaking in Japanese)` や `[音楽]` 系の出力を減らす目的で入れます。反復そのものへの主対策ではありませんが、副作用が小さいので早めに入れてよいです。

### Step 3: `--no-fallback` + temperature 0

```bash
-tp 0
-tpi 0
-nf
```

デフォルトでは decoder が失敗判定されたときに temperature fallback で再試行します。whisper.cpp の CLI help でも `--temperature`、`--temperature-inc`、`--no-fallback` が用意されています。([Hugging Face][4])
fallback は助かることもありますが、反復・幻覚時には高 temperature 側でさらに不安定になることがあります。日常ディクテーションでは、まず deterministic に寄せるのがよいです。

### Step 4: beam / best-of を下げる

現在ログでは `5 beams + best of 5` です。高い beam は通常は精度に効きますが、Whisper の反復ループでは「もっともらしい同じ文」を強化する場合があります。

反復が出るファイルでだけ、次を比較してください。

```bash
-bs 1 -bo 1
-bs 3 -bo 3
-bs 5 -bo 5
```

私なら日常プリセットはまず `-bs 3 -bo 3`、反復が強いなら `-bs 1 -bo 1` を試します。精度最優先なら `-bs 5` も残しますが、反復サンプルでは下げたほうが勝つことがあります。

### Step 5: fallbackを使うなら `-et 3.0`

`--entropy-thold` は反復検出に関係します。whisper.cpp discussion では、entropy threshold は直近32 token の繰り返し具合に関係し、しきい値を上げると反復に対してより積極的に retry する、という調査が共有されています。そこでは default 2.40 に対し、3.0 が短い検証で反復除去に効いたと述べられています。([GitHub][9])

ただし、これは fallback とセットで効く方向です。`-nf` と同時に使うと意味が薄くなります。

反復が出るが `-nf` で品質が悪い場合は、別プリセットとして：

```bash
-tp 0
-tpi 0.2
-et 3.0
-mc 64
# -nf は付けない
```

を試します。

### Step 6: `--suppress-regex` は最後

`suppress-regex` は「固定のゴミ表現を出させない」用途です。たとえば次のような既知ゴミです。

```text
ご視聴ありがとうございました
字幕視聴ありがとうございました
(speaking in Japanese)
```

反復一般には効きません。むしろ必要な token まで抑えると認識が壊れます。まずは postprocess 側で重複行を消すほうが安全です。

---

## 5. AirPods Pro / ffmpeg / 録音設定

### 16kHz mono pcm_s16le WAV は正しい

whisper.cpp README は `whisper-cli` が16-bit WAVを扱う例として、`ffmpeg -i input.mp3 -ar 16000 -ac 1 -c:a pcm_s16le output.wav` を示しています。([GitHub][2])
なので、あなたの録音形式はこの用途に合っています。

### `:6` 固定は壊れやすい

FFmpeg の AVFoundation input は `-i "[[VIDEO]:[AUDIO]]"` の形式で、device name または index を使えます。デバイス一覧は `-list_devices true` で列挙できます。([FFmpeg][10])
AirPods は再接続やOSアップデートで index が変わることがあります。`MIC_DEVICE=":6"` でも動きますが、堅牢化するなら起動時に device name を解決するほうが安全です。

```bash
"$FFMPEG_BIN" -hide_banner -f avfoundation -list_devices true -i "" 2>&1
```

ログに出る名前を使えるなら、indexより名前のほうが読みやすいです。ただし名前に特殊文字が入る場合があるので、最初は index + 起動時検証が現実的です。

### AirPods Pro mic は必ず比較対象にする

Apple は、Bluetooth ヘッドフォンでマイクを使うと、Bluetooth が「高品質再生モード」から「マイク＋再生モード」に切り替わり、音質が低下すると説明しています。([Apple Support][11])
これは再生音質の話として書かれていますが、ASR用途では「Bluetooth headset mic path が音声認識のボトルネックになり得る」と見たほうがよいです。

検証では、同じ文章を次で録って比較してください。

```text
A. AirPods Pro mic
B. MacBook内蔵マイク
C. 有線EarPods/USBマイク/外部USB-Cマイク
```

かなりの確率で、B または C のほうが英語 phrase の保持と反復抑制で有利です。AirPods は便利ですが、ASR精度最優先なら外部マイクの勝ち筋があります。

### ffmpeg 起動コマンドの小改善

今のコマンドに `-nostdin` を足すのがおすすめです。バックグラウンド実行時に ffmpeg が stdin を読みに行く余地を潰せます。

```bash
exec "$FFMPEG_BIN" -hide_banner -nostdin -loglevel warning -y \
  -f avfoundation -i "$MIC_DEVICE" \
  -ar 16000 -ac 1 -c:a pcm_s16le "$AUDIO_FILE"
```

さらに、録音開始確認は PID 生存だけでなく、ファイル生成も見たほうがよいです。

```bash
for _ in {1..20}; do
  if [[ -s "$AUDIO_FILE" ]]; then
    break
  fi
  /bin/sleep 0.05
done
```

ただし WAV は録音中ヘッダ未確定なので、最終 duration チェックは停止後に `ffprobe` で行うのが安全です。

停止後は `wait "$pid"` を入れて、ffmpeg の終了処理と WAV finalize を確実に待つのがよいです。

```bash
/bin/kill -INT "$pid" >/dev/null 2>&1 || fail "failed to stop recording process: pid=$pid" 1

for _ in {1..50}; do
  if ! is_pid_alive "$pid"; then
    break
  fi
  /bin/sleep 0.1
done

wait "$pid" 2>/dev/null || true
```

---

## 6. 推奨する最終パイプライン

### 推奨プリセット v1

まずこの設定を本線にします。

```bash
WHISPER_LANGUAGE="auto"
WHISPER_USE_VAD="false"

WHISPER_PROMPT='これは日本語と English が自然に混ざった dictation transcript です。英語で話された words and phrases は English spelling のまま残ります。今日は whisper.cpp と ffmpeg で local dictation pipeline を test します。Right Control を押して recording を start し、stop したら clipboard に copy します。Hammerspoon, Karabiner, AirPods Pro, pbcopy, initial prompt, VAD, beam size, temperature, hallucination, code-switching.'
```

```bash
whisper_args=(
  -m "$MODEL_PATH"
  -f "$AUDIO_FILE"
  -l "$WHISPER_LANGUAGE"
  --prompt "$WHISPER_PROMPT"
  -mc 64
  -tp 0
  -tpi 0
  -nf
  -sns
  -otxt
  -of "$TXT_PREFIX"
)
```

`--carry-initial-prompt` が使えるビルドなら追加します。

```bash
if "$WHISPER_BIN" -h 2>&1 | /usr/bin/grep -q -- '--carry-initial-prompt'; then
  whisper_args+=(--carry-initial-prompt)
fi
```

反復がまだ出るなら、この順に差し替えます。

```bash
# 反復対策 A: context をさらに減らす
-mc 32

# 反復対策 B: greedy寄り
-bs 1 -bo 1

# 反復対策 C: fallbackあり entropy retry
# この場合 -nf と -tpi 0 は外す
-tp 0 -tpi 0.2 -et 3.0 -mc 64
```

### large-v2 も必ず比較する

`large-v3` は英語や似た音の語で改善する一方、反復が出るサンプルがあります。GitHub issue でも large-v3 の反復報告があります。([GitHub][7])
あなたの用途では、`large-v2` が `large-v3` より安定する可能性があります。精度の絶対値ではなく「日常ディクテーションとして壊れにくいか」で比較してください。

```bash
MODEL_PATH="$HOME/models/whisper.cpp/ggml-large-v2.bin"
```

同じ音声ファイルで `large-v2` / `large-v3` を比較し、反復率・英語保持率・日本語自然さを見ます。

### Apple Silicon の高速化確認

M3 なら Metal または Core ML が効いているか確認してください。whisper.cpp は Apple Silicon を Metal / Core ML / Accelerate で最適化していると説明しています。([GitHub][2])
Core ML では encoder inference を Apple Neural Engine で実行でき、CPU-only より3倍超の speed-up になり得ると公式 README にあります。([GitHub][2])

ログに次のような行があるか見ます。

```text
whisper_backend_init: using Metal backend
system_info: ... METAL = 1 ...
```

または Core ML なら：

```text
whisper_init_state: loading Core ML model
system_info: ... COREML = 1 ...
```

Homebrew の `whisper-cpp` は現在 stable 1.8.6 が出ています。([Homebrew Formulae][12])
ただし、あなたの実行ログ断片には Metal/Core ML の行が見えていません。速度が十分でない場合はここを確認してください。

---

## 具体的な検証手順

### 1. 固定テスト音声を作る

毎回違う発話で比較すると判断できません。まず10本ほど固定文を録音して保存します。

例：

```text
今日は whisper.cpp と ffmpeg で local dictation pipeline をテストします。
Right Control を押して recording を start and stop します。
Hi there, can you hear me? これは日本語でも大丈夫ですか。
Hammerspoon and Karabiner are used for right Ctrl toggling.
タイ語で sabai dee mai と言うと sabai dee krap と返します。
VAD を使うと speech segments が細かく split されることがあります。
I want English phrases to stay in English, not katakana.
```

### 2. 同じ WAV に複数設定を走らせる

```bash
AUDIO=/tmp/local-dictation/dictation.wav
MODEL_V3="$HOME/models/whisper.cpp/ggml-large-v3.bin"
MODEL_V2="$HOME/models/whisper.cpp/ggml-large-v2.bin"

run_case() {
  name="$1"; shift
  /opt/homebrew/bin/whisper-cli \
    -m "$MODEL_V3" \
    -f "$AUDIO" \
    -l auto \
    --prompt "$WHISPER_PROMPT" \
    -otxt -of "/tmp/local-dictation/test-$name" \
    "$@" \
    >"/tmp/local-dictation/test-$name.log" 2>&1
}

run_case base
run_case mc64 -mc 64
run_case nofallback -mc 64 -tp 0 -tpi 0 -nf -sns
run_case greedy -mc 64 -tp 0 -tpi 0 -nf -sns -bs 1 -bo 1
run_case entropy -mc 64 -tp 0 -tpi 0.2 -et 3.0 -sns
```

### 3. 評価項目を決める

見るべき指標はこの4つです。

```text
英語保持:
  English phrase が英語表記で残ったか

日本語自然さ:
  日本語が不自然な翻訳調になっていないか

反復:
  同一文・同一phraseが連続していないか

処理時間:
  whisper_print_timings total time
```

WER/CERを厳密に測るより、日常ディクテーションでは「編集コスト」が一番重要です。

---

## 現在の awk 後処理の改善

今の postprocess は最低限として良いですが、反復対策と空結果対策を足すと実用性が上がります。

```bash
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
  if (line == "") next

  if (line == "[音声なし]" || line == "[音声]" || line == "(音声)") next
  if (line ~ /^\(speaking in .*Japanese.*\)$/) next
  if (line ~ /^(ご視聴ありがとうございました|字幕.*ありがとうございました)$/) next

  n = norm(line)

  # 直前行とほぼ同じなら捨てる。短すぎる行は誤爆防止で残す。
  if (length(n) >= 8 && n == prev) next

  print line
  prev = n
}
' "$TXT_FILE")"

if [[ -z "${text//[[:space:]]/}" ]]; then
  fail "empty transcription; clipboard not changed" 1
fi

printf '%s' "$text" | "$PBCOPY_BIN"
```

`--suppress-regex` より、まずこの postprocess のほうが安全です。

---

## 実装面の堅牢化ポイント

### PID / lock

右Ctrlは誤連打や key repeat が起きやすいので、PIDファイルに加えて lock を入れると安全です。macOS標準前提なら `flock` より atomic `mkdir` が簡単です。

```bash
LOCK_DIR="$DICTATION_STATE_DIR/lock"

if ! /bin/mkdir "$LOCK_DIR" 2>/dev/null; then
  exit 0
fi
trap '/bin/rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT
```

### ファイル名

`dictation.wav` 固定でも動きますが、検証フェーズでは timestamp を付けるほうがよいです。

```bash
RUN_ID="$(/bin/date +%Y%m%d-%H%M%S)"
AUDIO_FILE="$DICTATION_STATE_DIR/dictation-$RUN_ID.wav"
TXT_PREFIX="$DICTATION_STATE_DIR/dictation-$RUN_ID"
```

最後の成功結果だけ symlink で指すと便利です。

```bash
ln -sf "$AUDIO_FILE" "$DICTATION_STATE_DIR/latest.wav"
ln -sf "$TXT_PREFIX.txt" "$DICTATION_STATE_DIR/latest.txt"
```

### 右Ctrl単体の扱い

Karabiner で `right_control` の `to_if_alone` を使い、他キーと組み合わせた Control 操作は壊さない構成が堅いです。Hammerspoon の eventtap だけで右Ctrl down/upを取ると、通常の Ctrl 修飾と衝突しやすくなります。

理想は：

```text
Karabiner:
  right_control alone → toggle script
  right_control with other key → normal right_control

Hammerspoon:
  必要なら通知・sound・pasteだけ担当

bash:
  状態管理、録音、transcribe、pbcopy
```

### 自動ペースト

`AUTO_PASTE=false` は正しい初期値です。自動ペーストは便利ですが、パスワード欄やターミナルに誤爆します。入れるならアプリ whitelist を作るのが安全です。

---

## 最終推奨構成

私ならこうします。

```text
default:
  right Ctrl toggle
  ffmpeg avfoundation
  16kHz mono pcm_s16le wav
  VADなし
  large-v3
  -l auto
  code-switching prompt
  -mc 64
  -tp 0 -tpi 0 -nf
  -sns
  pbcopy
  auto pasteなし

fallback preset:
  large-v2
  -l auto
  same prompt
  -mc 64 or 32
  -bs 1 -bo 1

optional:
  English mode hotkey: -l en
  Japanese mode hotkey: -l ja
  VAD mode: 長い無音が入る録音だけ、pad/silence durationをかなり緩くする
```

この用途で一番効く改善は、おそらく次の順です。

```text
1. AirPods Pro mic と内蔵/有線/USBマイクの比較
2. -l auto + code-switching prompt
3. -mc 64 / 32
4. -nf + temperature 0
5. beam/best-of を 5 → 3 → 1 で比較
6. large-v2 比較
7. それでも必要なら English/Japanese 明示モード追加
```

`VAD=false` はそのままでよいです。今のサンプルでは、VADは速度にも品質にも寄与していません。むしろ日英混在ディクテーションでは、文脈を保ったまま Whisper に渡すほうが重要です。

[1]: https://github.com/openai/whisper "GitHub - openai/whisper: Robust Speech Recognition via Large-Scale Weak Supervision · GitHub"
[2]: https://github.com/ggml-org/whisper.cpp "GitHub - ggml-org/whisper.cpp: Port of OpenAI's Whisper model in C/C++ · GitHub"
[3]: https://developers.openai.com/cookbook/examples/whisper_prompting_guide "Whisper prompting guide"
[4]: https://huggingface.co/spaces/natasa365/whisper.cpp/blob/4c88a2785ff6ece8196fc54a8760b32060ca35cf/examples/cli/README.md "examples/cli/README.md · natasa365/whisper.cpp at 4c88a2785ff6ece8196fc54a8760b32060ca35cf"
[5]: https://github.com/argmaxinc/argmax-oss-swift "GitHub - argmaxinc/argmax-oss-swift: On-device Speech AI for Apple Silicon · GitHub"
[6]: https://github.com/SYSTRAN/faster-whisper "GitHub - SYSTRAN/faster-whisper: Faster Whisper transcription with CTranslate2 · GitHub"
[7]: https://github.com/ggml-org/whisper.cpp/issues/1507 "Whisper large v3 model repeats a lot · Issue #1507 · ggml-org/whisper.cpp · GitHub"
[8]: https://github.com/openai/whisper/discussions/1783 "Whisper Models are Poisoned? · openai whisper · Discussion #1783 · GitHub"
[9]: https://github.com/ggml-org/whisper.cpp/discussions/620 "Is there somewhere more detailed insight on arguments and their influence on the output? · ggml-org whisper.cpp · Discussion #620 · GitHub"
[10]: https://ffmpeg.org/ffmpeg-devices.html "      FFmpeg Devices Documentation
"
[11]: https://support.apple.com/en-us/102217?utm_source=chatgpt.com "If sound quality is reduced when using Bluetooth ..."
[12]: https://formulae.brew.sh/formula/whisper-cpp "Homebrew Formulae: whisper-cpp"
