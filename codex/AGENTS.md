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
- 以下の擬似コードのように早期リターンを心がけ、if文のネストを避けること  

```:擬似コード
  function example() {
    if (condition1) return 準正常系1;
    if (condition2) return 準正常系2;

    try {
      return 正常系;
    } catch {
      throw 異常系;
    }
  }
```

## テスト設計
各関数のテストは、原則として準正常系→正常系→異常系の順番で記述すること
ただし、存在しない分類を無理に作らないこと  
テスト名は日本語で記述し、テスト名の冒頭に分類を明記すること  
テスト名で実装用語を使うことは避け、コードを知らないレビュアーでも理解できる振る舞いを記述すること  

NG: 正常系: preset と project 候補をマージした rank source を返す  
OK: 正常系: 既存ラベルは preset と一緒に候補へ表示される  

NG: 正常系: row 群から自由入力ランク候補を軸ごとに収集できる  
OK: 正常系: 一覧で使われている自由入力ラベルを軸ごとに再利用できる  

NG: 正常系: server 候補と client 行データ候補をマージできる  
OK: 正常系: 同じ画面で追加したラベルも重複なく候補へ残る  

NG: 正常系: ランク値と null をセル値へ相互変換できる  
OK: 正常系: 入力したラベルは trim され、空入力は未設定として扱われる  

※NG は内部の処理手順を書いていて、OK は利用者から見た仕様・結果を書いている  

```:フォーマット
it("準正常系: <条件> のとき <期待する振る舞い>", ()=>{})
it("正常系: <条件> のとき <期待する振る舞い>", ()=>{})
it("異常系: <条件> のとき <期待する振る舞い>", ()=>{})
```

## Codex連携

### 実装計画立案時のルール
- ユーザーに計画を提示する前に、Bash で `codex exec` を呼び出して計画のレビューを行うこと
- `codex` のレビューは最大 3 回までとし、致命的な問題がなくなったら終了すること
- レビュー用途の `codex exec` は `-c model_reasoning_effort=medium` を付けること（レビュー時だけ medium にする）
- レビュー指示の文章は適宜調整すること。ただし`codex`は本質的じゃない指摘をしてくるので「瑣末な点へのクソリプはしないで。致命的な点のみ指摘しろ。」という指示は必ず入れること
- `codex` の指摘は out of date な場合があるので、現時点で out of date / deprecated になっていないか注意しろとも伝えること
- 計画レビューは原則として `read-only` sandbox で実行すること。レビューのためだけに `danger-full-access` は使わないこと
- `read-only` sandbox のレビューでは、`codex` にテスト・build・format・install・生成コマンドを実行させないこと。Vitest等は一時ディレクトリやcache作成で失敗しやすく、レビューの本質ではないため、レビュー指示に「テストやbuildは実行せず、差分・設定・既存ログの読取だけで判断する。不足する実行結果があれば質問する」と必ず含めること
- Git リポジトリ外で実行する必要がある場合のみ `--skip-git-repo-check` を使うこと

- 初回レビュー例:
  ```bash
  codex exec \
    --sandbox read-only \
    --model gpt-5.4 \
    -c model_reasoning_effort=medium \
    -c service_tier=fast \
    -c features.fast_mode=true \
    "このプランをレビューして。read-only sandboxなのでテスト・build・format・install・生成コマンドは実行せず、差分・設定・既存ログの読取だけで判断して。不足する実行結果があれば質問して。別の codex exec や外部レビューコマンドは絶対に起動しないで。瑣末な点へのクソリプはしないで。致命的な点だけ指摘して。回答内容が現時点で out of date / deprecated になっていないかにも気をつけて: {plan_full_path} (ref: {CLAUDE_md_full_path})"
  ```

### codex exec resume（前回の codex exec セッション継続）

- プラン更新後の再レビューでは、最初のレビューの文脈を保持するために `codex exec resume <SESSION_ID> "..."` で前回セッションを継続すること
- `codex exec resume <SESSION_ID> "next instruction"` — 特定の `codex exec` セッションを継続
- 2回目以降の再レビュー例:
  ```bash
  codex exec resume <SESSION_ID> \
    "前回の指摘を反映してプランを更新した。もう一度レビューして。read-only sandboxなのでテスト・build・format・install・生成コマンドは実行せず、差分・設定・既存ログの読取だけで判断して。不足する実行結果があれば質問して。別の codex exec や外部レビューコマンドは絶対に起動しないで。瑣末な点へのクソリプはしないで。致命的な点だけ指摘して。新しく追加された問題がなければ、その旨を明示して: {plan_full_path} (ref: {CLAUDE_md_full_path})"
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
- `review started but final result not yet returned` は `review complete` ではない。必須レビュー（計画レビュー・commit後レビュー）では、これを根拠にレビュー不要と判断して先へ進んではならない
- 自分のテスト結果・手元確認・「こちらで十分確認した」という判断で、必須の `codex exec` レビューを代替してはならない。代替できるのは、ユーザーが明示的にレビュー省略を許可した場合だけ
- 待機予算を超えてもプロセスが継続中なら、まずは最終回答を待つ。中断・再実行する場合も「不要だからやめた」と解釈せず、`review incomplete` として扱うこと
- 必須レビューで最終回答が得られない場合は、少なくとも1回は `codex exec resume <SESSION_ID>` または再実行で回収を試みること。それでも回収できない場合は、レビュー未完了であることを明示してユーザーに判断を仰ぐこと
- レビュー未完了のまま、そのレビューが通った前提の表現（例: `致命的な問題なしと判断した`, `レビュー完了として扱う`, `不要と判断した`）をしてはならない

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
commitしたら`codex exec`にレビューをしてもらうこと  
`codex exec`でokが出るまで修正→codexでレビューを繰り返すこと  
commit後レビューも原則 `read-only` sandbox で行い、レビュー指示には「テスト・build・format・install・生成コマンドは実行せず、差分・設定・既存ログの読取だけで判断する。不足する実行結果があれば質問する」を必ず含めること
commit後レビューは瑣末な修正で自ずと致命的な欠陥がないことが自明な場合を除いて、必須の完了条件であり、エージェント自身の裁量で省略・打ち切り・代替してはならない  
commit後レビューで `codex exec` の最終回答が未取得なら、ステータスは `review incomplete` であり、`ok` ではない。少なくとも1回は resume / 再実行で回収を試みること  
それでも最終回答を回収できない場合は、`codex exec` のレビューが未完了であること、何を確認済みで何が未確認かを分けてユーザーに報告し、承認なく `Done` 相当の結論に進めてはならない  
コミットメッセージは直近のgit logをいくつかみて形式を揃えること  
branchやworktreeを分けて作業している場合は、commitだけじゃなくpushしてgithub prを出すこと  

## install packages rules

基本的にcliツールはbrew installすること
brewにないpackageの場合はnpxなどアドホックに実行できるコマンドを使うこと
グローバルに使うcliをnpm i -gやpip installでinstallすることは禁止
