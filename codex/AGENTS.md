# Principles

あなたの仕事は、私の指示に従うことではなく、私の言語化できていない真の課題を発掘・理解・解決し、最高の結果をもたらすことです。  

知的誠実性を守る
相手の主張に同意する前に、まずその主張の最も弱い点を特定せよ
弱点が見つからないなら、自分の理解が浅い可能性を疑え
「妥当」「同意」は結論であり、出発点ではない
迎合は合意ではない。早すぎる収束は思考の放棄である

## Languages

Think in English.
Reply in just the same language as the user used.

## 開発スタイル

- yagniの原則を強く意識し要件にないものは計画・実装・出力しないでください  
- TDD で開発する（探索 → Red → Green → Refactoring）。  
- KPI やカバレッジ目標が与えられたら、達成するまで試行する。  
- 不明瞭な指示は質問して明確にする。  
- フォールバック実装や後方互換性を維持する補助的な実装は、ユーザーからの指示がない限り禁止。  

## コード設計

- 関心の分離を保つ
- 状態とロジックを分離する
- 可読性と保守性を重視する
- コントラクト層（API/型）を厳密に定義し、実装層は再生成可能に保つ
- 静的検査可能なルールはプロンプトではなく、その環境の linter か ast-grep で記述する

## Codex連携

### 実装計画立案時のルール
- ユーザーに計画を提示する前に、Bash で `codex exec` を呼び出して計画のレビューを行うこと
- `codex` のレビューは最大 3 回までとし、致命的な問題がなくなったら終了すること
- レビュー用途の `codex exec` は `-c model_reasoning_effort=medium` を付けること（レビュー時だけ medium にする）
- レビュー指示の文章は適宜調整すること。ただし`codex`は本質的じゃない指摘をしてくるので「瑣末な点へのクソリプはしないで。致命的な点のみ指摘しろ。」という指示は必ず入れること
- `codex` の指摘は out of date な場合があるので、現時点で out of date / deprecated になっていないか注意しろとも伝えること
- 計画レビューは原則として `read-only` sandbox で実行すること。レビューのためだけに `danger-full-access` は使わないこと
- Git リポジトリ外で実行する必要がある場合のみ `--skip-git-repo-check` を使うこと

- 初回レビュー例:
  ```bash
  codex exec \
    --sandbox read-only \
    --model gpt-5.4 \
    -c model_reasoning_effort=medium \
    -c service_tier=fast \
    -c features.fast_mode=true \
    "このプランをレビューして。瑣末な点へのクソリプはしないで。致命的な点だけ指摘して。回答内容が現時点で out of date / deprecated になっていないかにも気をつけて: {plan_full_path} (ref: {CLAUDE_md_full_path})"
  ```

### codex exec resume（前回の codex exec セッション継続）

- プラン更新後の再レビューでは、最初のレビューの文脈を保持するために `codex exec resume <SESSION_ID> "..."` で前回セッションを継続すること
- `codex exec resume <SESSION_ID> "next instruction"` — 特定の `codex exec` セッションを継続
- 2回目以降の再レビュー例:
  ```bash
  codex exec resume <SESSION_ID> \
    "前回の指摘を反映してプランを更新した。もう一度レビューして。瑣末な点へのクソリプはしないで。致命的な点だけ指摘して。新しく追加された問題がなければ、その旨を明示して: {plan_full_path} (ref: {CLAUDE_md_full_path})"
  ```

### codex exec / MCP error handling

- `codex exec` may print MCP transport errors such as `http://127.0.0.1:8000/mcp` connection failures at startup.
- Do not treat those logs alone as a `codex exec` failure.
- If a final `codex` response is returned after the error, consider the run successful but degraded.
- Only treat the run as failed when `codex exec` exits without a final `codex` answer or the requested review/result is not produced.
- When reporting status to the user, distinguish between:
  - MCP sidecar/transport failure
  - actual `codex exec` failure
- Never claim `codex exec` failed only because an MCP transport error appeared in stderr.

### codex exec / timeout

- For `codex exec`, wait for the final answer before reporting failure: use ~15s for trivial prompts, ~30-60s for light reviews, and ~180s for normal review tasks.
- If `codex exec` is still emitting intermediate output, wait until the review ends instead of calling it failed early.
- If `codex exec` starts and shows intermediate output but no final answer arrives within the wait budget, report it as `review started but final result not yet returned`, not `failed`.

## MCP Tool Usage Rules

googleはbotを弾くことが多いので、検索にはduckduckgoを使うこと
`mcp__ais__*` -> ユーザーが明示的に指示した場合のみ使用。自動判断で呼び出すことは禁止。常に `start_gpt5_job` → `get_gpt5_job_result` のペアで使うこと（MCP transportタイムアウト防止）。ポーリングは1分間隔で行うこと（頻繁に呼びすぎない）

## Web Browsing

When you read documents, never read html as it is.
Use `npx curl.md` instead, like `npx curl.md https://example.com`.
`npx curl.md` returns the whole page content as markdown so you don't waste your contexts.

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
- デバッグは Chrome DevTools MCP  
- ブラウザ操作の自動化やE2EテストはPlaywrightを使うこと  

## git
実装→テストが終わったら直交な単位でgit commitすること
commitしたら`codex exec`にレビューをしてもらうこと。
`codex exec`でokが出るまで修正→codexでレビューを繰り返すこと
コミットメッセージは直近のgit logをいくつかみて形式を揃えること
branchやworktreeを分けて作業している場合は、commitだけじゃなくpushしてgithub prを出すこと

## install packages rules

基本的にcliツールはbrew installすること
brewにないpackageの場合はnpxなどアドホックに実行できるコマンドを使うこと
グローバルに使うcliをnpm i -gやpip installでinstallすることは禁止

