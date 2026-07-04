# cursor-compose: AX API による Cursor Composer 自動化の仕組み

`bin/cursor-compose` は Cursor IDE の Composer にプロンプトを外部から
送信する CLI。PM エージェント(Codex / Claude Code)がコーディング作業を
Cursor Composer に委譲するために使う。運用手順は
`skills/cursor-composer-delegation/SKILL.md` を参照。

## AppleScript ではなく AX API を使っている

初版は AppleScript (`osascript` + System Events) で実装していたが、
現行版は Swift から macOS Accessibility API (AX API) を直接呼んでいる。
`bin/src/cursor-compose.swift` がその実体で、コンパイル済みバイナリ
`bin/cursor-compose-ax` は gitignore 対象(各マシンでビルドする):

```bash
swiftc -O ~/dotfiles/bin/src/cursor-compose.swift -o ~/dotfiles/bin/cursor-compose-ax
```

### 初版: AppleScript (キーストローク注入)

```
osascript → System Events → keystroke "i" using {command down} → 仮想キー入力
```

- Cursor を最前面にアクティブ化する必要がある
- ユーザーのキー入力・フォーカスとバッティングする(実害が出た)
- プロンプト受け渡しにクリップボードを使うため、コピー操作とも干渉
- `delay` 頼みでタイミングが不安定

### 現行版: AX API 直接呼び出し

```
cursor-compose (bash) → cursor-compose-ax (Swift) → AX API → Cursor プロセス
```

処理の流れ:

1. `AXUIElementCreateApplication(pid)` で Cursor プロセスの UI ツリーを取得
2. Electron は AX ツリーを遅延公開するため `AXManualAccessibility = true` を
   セットして強制的に有効化
3. ツリーを走査して Composer の `AXTextArea` を発見し、`AXValue` 属性に
   プロンプト文字列を**直接代入**(タイピングを一切しない)
4. "Send message" ボタンに `AXPress` アクションを実行(クリック座標の
   エミュレーションではなく、ボタン要素への直接通知)
5. `--new` のときは "New Agent" ボタンを同様に `AXPress`

すべて Cursor プロセスにスコープされるため:

- **フォーカスを奪わない** — ユーザーは他アプリで作業を継続できる
- **クリップボードを使わない**
- **文字列が逐語的に届く** — 数KBの長文・日本語・引用符・バッククォート・
  `$vars`・リテラル `\n` すべて安全

### 実は同じ土台

AppleScript の System Events も内部では同じ AX API を呼んでいる。つまり
AppleScript 方式は「AX API の上にキーボード・マウス再現の抽象化を被せた
もの」であり、現行版はその抽象化を剥がして生の AX API を使っている。
フォーカス依存やタイミング問題は抽象化層に由来するもので、一段深い層を
直接叩けば消える。

## 前提条件

- Cursor.app が起動していて Composer ペインが開いていること
  (閉じていると "textarea not found" で失敗する)
- 呼び出し元ターミナルに Accessibility 権限
  (System Settings > Privacy & Security > Accessibility)

## branch / worktree 切り替えについて

AX API で Cursor の UI(ステータスバーのブランチピッカーなど)を操作する
ことも原理的には可能だが、**その必要はない**。計測した結果:

- **branch 切り替え**: シェルから `git switch <branch>` するだけでよい。
  Cursor はファイルウォッチャーでワーキングツリーを自動追従するため、
  IDE 側の操作は不要(検証済み: 裏で `git switch -c` しても Cursor は
  フォーカス移動なしで追従した)。
- **worktree / 別リポジトリ**: `cursor <dir>`(Cursor 純正 CLI)で開く。
  `cursor-compose --dir <path>` がこれをラップしている。新しいウィンドウを
  開く瞬間だけ Cursor がアクティブになる(唯一のフォーカス影響ポイント)。
  既に開いている worktree への切り替えも `cursor <dir>` が既存ウィンドウを
  再利用する。

つまり「エディタの状態」は git CLI と cursor CLI で外から制御でき、
AX API の出番はプロンプト送信だけに絞ってある。UI 操作面を増やすほど
Cursor のアップデートで壊れやすくなるため、この分担は意図的なもの。

注意: 同一ウィンドウ内で Composer が作業中に branch を切り替えると、
Composer は切り替え後のワーキングツリーに書き込む。タスク実行中の
branch/worktree 変更は避け、diff 検収が終わってから切り替えること。
並行タスクを走らせたい場合は worktree ごとに Cursor ウィンドウを分ける。

## 制約・既知の挙動

- 送信先は「Cursor プロセス内で最初に見つかった AXTextArea」。複数
  ウィンドウを開いている場合、意図しないウィンドウの Composer に届く
  可能性がある。並行運用時は送信後の diff 検収で必ず確認する。
- Composer 作業中の連投は同一チャットにキューされ順次処理される
  (動作はするが、タスクごとの検収ができないため非推奨)。
- Cursor の UI 構造(ボタンの accessibility description "Send message" /
  "New Agent")に依存しているため、Cursor のメジャーアップデートで
  壊れたら `/tmp` に AX ツリーのプローブを書いて要素名を再調査する。
