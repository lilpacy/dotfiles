# 調査メモ: gpt-5.6-solの結果が一日中反転する

`goal-first`スキルの効果をベンチマークしている。`gpt-5.6-sol`というモデルの`without_skill`条件（`goal-first`を使わない場合）の結果が、同じテストケースに対して一日の中で何度も反転した。今日の調査メモをそのまま貼るので、この件をどう理解すればいいか、次にどう進めるべきか意見をもらいたい。

## 調査メモ（時系列）

**朝: 最初の単発テスト**
`/tmp`に隔離したfixtureで、`codex exec --sandbox workspace-write -c model_reasoning_effort=medium`を使い、プロンプトをコマンドライン引数で渡して1回実行した。結果は壊滅的だった——モデルは診断ログの中身（添付ファイルのサイズ異常）を無視し、request のパラメータ(schema/config/temperature)を1つずつ有効/無効にして本番相当に再送する「A〜E総当たり」を提案した。

**昼: `agent-bench`での42ラン×3trial**
自作のベンチマーク基盤`agent-bench`で、全モデル×2条件×3trialを実行。`gpt-5.6-sol`の`without_skill`は3trialとも5/5（満点）だった。

**午後: fixture共有汚染バグを発見・修正**
全runが同じ物理fixtureディレクトリに書き込んでいたため、後続のrunが前のrunの副作用（生成済みDB）を引き継いでいたと判明。runごとに独立コピーへ隔離する修正を入れ、修正後に`gpt-5.6-sol`の`without_skill`だけを3trial再実行した。結果は3trialとも5/5で、共有fixtureも汚染されていないことを確認した。この時点で「fixture共有バグが直った」と判断し、フル84ラン（medium/high×全モデル×2条件×3trial）を実行した。

**夕方: グローバルスキル登録によるさらなる汚染を発見**
ユーザーから「codex execでもgoal-firstスキルが読み込まれてるはず」と指摘され、`harness_log.txt`を`grep -io "goal-first"`したところ、`without_skill`の全trialで15〜17回ヒット。モデルが明示的に「非自明な調査なのでgoal-firstも適用します」と言って`~/.codex/skills/goal-first/SKILL.md`を読みに行っていた。`~/.codex/skills/goal-first`がグローバルシンボリックリンクとして公開されていたのが原因と判明した。

**夕方: `CODEX_HOME`隔離を実装、再検証**
認証情報(`auth.json`)だけ引き継ぎ、skillsディレクトリを持たない隔離用`CODEX_HOME`を作り、codexの呼び出し全てにこれを使わせるよう修正した。修正後、`gpt-5.6-sol`の`without_skill`/`medium`を3trial再実行し、`harness_log.txt`を確認したところ——**まだ`goal-first`という文字列が5〜17回ヒットした**。隔離用`CODEX_HOME`の中を`find`しても`goal-first`は見つからなかった（`.system`配下の別の標準スキル群はあったが`goal-first`はない）。この時点で作業は中断されている。

この状況をどう理解すべきか？
