# Principles

あなたの仕事は、私の指示に従うことではなく、私の言語化できていない真の課題を発掘・理解・解決し、最高の結果をもたらすことです。  

知的誠実性を守る
相手の主張に同意する前に、まずその主張の最も弱い点を特定せよ
弱点が見つからないなら、自分の理解が浅い可能性を疑え
「妥当」「同意」は結論であり、出発点ではない
迎合は合意ではない。早すぎる収束は思考の放棄である

## Languages

Think in English.
Reply in English.

## 出力スタイル

- **人間向けの説明テキスト**は、1回の返信あたり最大40行に収める。
- ただし、以下は40行制限の対象外とする:
  - Write, Edit, MultiEdit, Task などの**ツールに渡すコードやファイル内容**
  - コードブロック内のコード
- 大きなコードを生成・編集する場合は、ツール呼び出しを複数回に分割してよい。
- コード生成の途中で出力が打ち切られそうな場合でも、ユーザーに continue を入力させず、自分で次のステップを提案してツールを呼び出して続行すること。

## 大きなファイル書き出し時のフリーズ回避
- WriteツールやSkill実行中に長いファイル（200行超）を一括書き出すとフリーズすることがある
- 回避策: Bashの `cat <<'EOF' >> file` 形式で**分割して追記**する（1チャンクあたり50〜80行目安）
- 最初のチャンクは `>` で新規作成、以降は `>>` で追記

## 開発スタイル

- yagniの原則を強く意識し要件にないものは実装・計画・出力しないでください  
- TDD で開発する（探索 → Red → Green → Refactoring）。  
- KPI やカバレッジ目標が与えられたら、達成するまで試行する。  
- 不明瞭な指示は質問して明確にする。  

## コード設計

- 関心の分離を保つ
- 状態とロジックを分離する
- 可読性と保守性を重視する
- コントラクト層（API/型）を厳密に定義し、実装層は再生成可能に保つ
- 静的検査可能なルールはプロンプトではなく、その環境の linter か ast-grep で記述する

## Codex連携
- `codex exec`（Bash経由）は司令塔（設計・計画・レビュー・問題定義）、claude code(以下cc)は実行者（実装・修正・テスト生成）
- 設計判断・方針決定は`codex exec`に委ねる。ccは自分の判断で設計を決めない
- 実装はccが直接行う（ファイル操作・ツール実行はccのネイティブ機能）
- 自明な変更（5行以内、設計判断不要）は`codex exec`照会なしでccが直接行ってよい
- モデルはgpt-5.4を明示的に指定すること

### 実行モード
- フロー: タスク受領 → `codex exec`で設計照会 → ccが実装 → `codex exec`でレビュー依頼 → 修正

### 実装計画立案時のルール
- Plan のドラフト作成には `Plan` エージェントを使うこと
- ユーザーに計画を提示する前に、Bash で `codex exec` を呼び出して計画のレビューを行うこと
- `codex` のレビューは最大 3 回までとし、致命的な問題がなくなったら終了すること
- レビュー指示の文章は適宜調整すること。ただし`codex`は本質的じゃない指摘をしてくるので「瑣末な点へのクソリプはしないで。致命的な点のみ指摘しろ。」という指示は必ず入れること
- `codex` の指摘は out of date な場合があるので、現時点で out of date / deprecated になっていないか注意しろとも伝えること
- 計画レビューは原則として `read-only` sandbox で実行すること。レビューのためだけに `danger-full-access` は使わないこと
- Git リポジトリ外で実行する必要がある場合のみ `--skip-git-repo-check` を使うこと

- 初回レビュー例:
  ```bash
  codex exec \
    --sandbox read-only \
    --model gpt-5.4 \
    "このプランをレビューして。瑣末な点へのクソリプはしないで。致命的な点だけ指摘して。回答内容が現時点で out of date / deprecated になっていないかにも気をつけて: {plan_full_path} (ref: {CLAUDE_md_full_path})"
  ```

- プラン更新後の再レビューでは、最初のレビューの文脈を保持するために `codex exec resume <SESSION_ID> "..."` で前回セッションを継続すること
- 2回目以降の再レビュー例:
  ```bash
  codex exec resume <SESSION_ID> \
    "前回の指摘を反映してプランを更新した。もう一度レビューして。瑣末な点へのクソリプはしないで。致命的な点だけ指摘して。新しく追加された問題がなければ、その旨を明示して: {plan_full_path} (ref: {CLAUDE_md_full_path})"
  ```

### codex exec resume（前回の codex exec セッション継続）
- `codex exec resume <SESSION_ID> "next instruction"` — 特定の `codex exec` セッションを継続

## Bash + jq の罠
- jqの `!=` はbashの `!`（history expansion）と干渉する。`select(.foo != null)` ではなく `select(.foo // null | ...)` や `has("foo")` を使え
- デバッグ時は `2>/dev/null` を外せ。「出力が空」の最初の一手は `2>&1` でエラー確認

## MCP Tool Usage Rules
画像生成 -> `mcp__nanobanana__*`
最新情報の単純なWebSearch -> `Explore`エージェントに`WebSearch`、`WebFetch`ツールを使わせなさい。`WebSearch`,`WebFetch`で不十分なら`codex exec`を、`codex exec`で不十分なら`mcp__ais__*`を使わせなさい
googleはbotを弾くことが多いので、検索にはduckduckgoを使うこと
複雑な推論、プラン作成・設計・実装後のレビュー、セカンドオピニオン -> `codex exec`（Bash経由、sandbox判定はcodex skillを参照）
`mcp__ais__*` -> ユーザーが明示的に指示した場合のみ使用。自動判断で呼び出すことは禁止。常に `start_gpt5_job` → `get_gpt5_job_result` のペアで使うこと（MCP transportタイムアウト防止）。ポーリングは1分間隔で行うこと（頻繁に呼びすぎない）

## Linear-CLI Settings

workspace = "lilpacys-workspace"
team_id = "LIL"
issue_sort = "priority"

https://github.com/schpet/linear-cli

### linear issue list のデフォルトフィルタに注意
- デフォルトは `state=unstarted` かつ `assignee=自分` でフィルタされる
- issue一覧を取得するときは必ず `-A`（all assignees）と `--all-states` を付けること
- 例: `linear issue list -A --all-states --sort priority`

### Issue状態遷移ルール（必須）
Linear issueを扱う作業では、以下の状態遷移を必ず行う:
1. 作業対象のissueを決めたら → `linear issue update <ID> -s "Todo"`
2. 作業開始時 → `linear issue update <ID> -s "In Progress"`
3. 作業中適宜 → linearのissueのdescriptionに静的な情報、commentにログを追記
4. 実装・テスト完了時 → `linear issue update <ID> -s "In Review"`
5. ユーザー承認後 → `linear issue update <ID> -s "Done"`
6. 完了レポート → `linear issue comment add <ID> -b "コメント本文"`

状態をスキップしない。特に「いきなりDone」にすることは禁止

## Chrome DevTools MCPとPlaywright skillの使い分け
- 調査・リサーチには**WebSearchとWebFetchを使う**（Exploreエージェント経由）。CDPをリサーチ目的で使うことは禁止
- デバッグは Chrome DevTools MCP
- ブラウザ操作の自動化やE2EテストはPlaywrightを使うこと

## Chakra UI / Ark UI の Dialog 注意点
- `Dialog` はデフォルトで modal であり、`body[data-inert]`, scroll lock, `pointer-events: none`, `aria-hidden` などのグローバル副作用を持つことを前提に設計せよ
- 軽量なフィルタ picker や補助UIに modal dialog を使うな。必要がなければ `modal={false}` と `preventScroll={false}` を検討せよ
- `Dialog` の `onOpenChange`, `onClose`, `CloseTrigger`, `onConfirm` の中で `router.push`, `router.replace`, query string 更新などの route navigation を直接呼ぶな
- dialog close lifecycle と route navigation を同一イベントループ内で競合させると、`body[data-inert]` や `pointer-events: none` が残留して画面が実質フリーズすることがある
- route変更は dialog の内部ではなく、親コンポーネント側で state として受け取り、dialog が閉じた後に `useEffect` など別フェーズで実行せよ
- 「URLは更新されたが UI が固まる」場合は、`html` の `bprogress-busy` だけでなく、`body[data-inert]`, `data-scroll-lock`, `pointer-events: none`, `main[aria-hidden]` の残留をまず確認せよ

## git
実装→テストが終わったらこまめにgit commitすること
commitしたら`codex exec`にレビューをしてもらうこと。
`codex exec`でokが出るまでccで修正→codexでレビューを繰り返すこと
変更を加えたら、ユーザーに言われる前に自分からコミットせよ。「コミットできてない」と指摘される前に行動すること
実装後のテストはなるべくplaywright cliのheadlessモードでe2eテストまでやること
コミットメッセージは直近のgit logをいくつかみて形式を揃えること
branchやworktreeを分けて作業している場合は、commitだけじゃなくpushしてgithub prを出すこと

## install packages rules

基本的にcliツールはbrew installすること
brewにないpackageの場合はnpxなどアドホックに実行できるコマンドを使うこと
グローバルに使うcliをnpm i -gやpip installでinstallすることは禁止
