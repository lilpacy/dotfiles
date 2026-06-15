# Mic Selection Plan

## 目的

macOS のデフォルト入力マイクを `peco` で選べる公開コマンドを追加し、ローカルディクテーションは常に macOS のデフォルト入力を使うようにする。

この方針では、dictation 専用のマイク設定を持たない。マイク選択は OS 全体の入力設定として扱い、dictation は録音パイプラインだけに集中する。

## 判断

前案では `dictation` 側に `mic-name` / `mic-device` を永続化し、録音開始時に ffmpeg の AVFoundation device index へ解決する予定だった。

その設計は dictation だけの入力を変えたい場合には有効だが、今回の要件は「macOS 側のデフォルトマイクを切り替え、dictation もそれに従う」方が自然である。

そのため、次の設計に切り替える。

```text
bin/select-mic
  -> macOS の default input device を変更する汎用CLI

dictation/
  -> 常に macOS default input を録音する
```

## 追加する公開コマンド

```text
bin/select-mic
```

`select-mic` は dictation 専用ではない。macOS のデフォルト入力マイクを変更する dotfiles 全体の公開コマンドとして `bin/` に置く。

コマンド名を `select-dictation-mic` にしない理由:

- 変更対象は dictation の内部設定ではなく macOS の default input device である。
- Zoom、Teams、Slack、ブラウザなど他アプリの入力にも影響する。
- 名前に dictation を含めると、影響範囲を誤解しやすい。

## 依存コマンド

```text
peco
SwitchAudioSource
```

`peco` は既に `homebrew/formula` にある。

`SwitchAudioSource` は `switchaudio-osx` formula で入れる。

```text
homebrew/formula
  switchaudio-osx
```

`select-mic` は依存コマンドがない場合に失敗させる。代替 UI や AppleScript fallback は入れない。

## select-mic の責務

`select-mic` は次だけを担当する。

1. `SwitchAudioSource -a -t input -f cli` で入力デバイス一覧を取る。
2. `SwitchAudioSource -c -t input -f cli` で現在のデフォルト入力を取る。
3. 一覧を `peco` に渡してユーザーに選ばせる。
4. 選択された名前を `SwitchAudioSource -s "$name" -t input` に渡す。
5. 変更後の現在値を表示する。

`select-mic` は dictation の設定ファイルを読まない。dictation の状態も変更しない。

`SwitchAudioSource` の既定出力は人間向け表示なので、パース対象にはしない。デバイス名の一覧と現在値は必ず `-f cli` の出力を使う。

## UI 契約

`select-mic` は対話型ターミナルで使う。

```text
$ select-mic
* MacBook Pro Microphone
  AirPods Pro
  USB Microphone
```

現在のデフォルト入力には `* ` を付ける。`peco` で選択した後は、`* ` を取り除いたデバイス名を `SwitchAudioSource` に渡す。

`peco` に渡す表示は `select-mic` 側で作る。`SwitchAudioSource` の human 出力に含まれる装飾や文言は使わない。

キャンセル時は何も変更せず、終了コード `130` で終了する。

## dictation 側の変更

`dictation/scripts/config.sh` の `MIC_DEVICE` を macOS default input に固定する。

```sh
MIC_DEVICE=":default"
```

`dictation/scripts/start.sh` はこれまで通り `MIC_DEVICE` を ffmpeg に渡す。

```sh
ffmpeg -f avfoundation -i "$MIC_DEVICE"
```

この構成では、録音前に `select-mic` で macOS の default input を変えると、dictation も同じマイクを使う。

## 検証済みの前提

手元の ffmpeg 8.0.1 では、AVFoundation input として `:default` が短時間録音で成功した。

```sh
ffmpeg -hide_banner -nostdin -loglevel warning \
  -f avfoundation -i ':default' \
  -t 0.1 -vn -f null -
```

この実装では `:default` が使えない環境向けの fallback は入れない。動作しない場合は ffmpeg のエラーとして失敗させる。

## 影響範囲

`select-mic` は macOS のデフォルト入力を変更するため、dictation 以外にも影響する。

影響する例:

- Zoom
- Microsoft Teams
- Slack
- ブラウザの WebRTC 入力
- macOS の音声入力

これは設計上の意図である。dictation だけのマイク切り替えが必要になった場合は、別途 dictation 専用の入力選択を再設計する。

## 録音中の変更

`select-mic` は OS の入力設定を変更する汎用コマンドなので、dictation の録音状態は見ない。

録音中に `select-mic` を実行しても、既に起動している ffmpeg の入力が切り替わる保証はしない。変更は次回録音から有効と考える。

## テスト計画

Bats に次を追加する。

```text
準正常系: 現在の入力マイクが一覧で選択状態として表示される
正常系: 選択した入力マイクをmacOSのデフォルト入力に設定できる
正常系: dictationはmacOS default inputを録音入力として使う
異常系: pecoでキャンセルするとマイクを変更しない
異常系: SwitchAudioSourceがないと失敗する
異常系: pecoがないと失敗する
```

既存の日本語テスト命名規則に合わせ、準正常系、正常系、異常系の順で追加する。

## 実装手順

1. `homebrew/formula` に `switchaudio-osx` を追加する。
2. `bin/select-mic` を追加する。
3. `dictation/scripts/config.sh` の `MIC_DEVICE` を `:default` に変更する。
4. `dictation/Makefile` の lint 対象に `../bin/select-mic` を追加する。
5. Bats fixture に `SwitchAudioSource` と `peco` の stub を追加し、`select-mic` と dictation default input のテストを追加する。
6. `dictation/README.md` と `dictation/docs/architecture.md` に、マイク選択は `bin/select-mic` が所有し、dictation は default input を使う方針を追記する。
7. `make lint && make test` を通す。

## やらないこと

- dictation 配下に `mic.sh` を追加しない。
- dictation 専用の `mic-name` / `mic-device` 永続設定を追加しない。
- `local-dictation set-mic` や `local-dictation set-mic-name` は追加しない。
- Hammerspoon chooser は追加しない。
- `SwitchAudioSource` がない場合の AppleScript fallback は追加しない。
