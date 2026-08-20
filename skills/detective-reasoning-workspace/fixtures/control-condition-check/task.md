# レビュー依頼: この結果は信じてよいか

`goal-first` というスキルの効果をベンチマークしている（`agent-bench`というツールを使い、`codex exec`でモデルを動かす）。

- `with_skill`: プロンプトに`goal-first`のSKILL.md本文を埋め込んで実行
- `without_skill`: 素のプロンプトのみ（`goal-first`は埋め込まない）
- `goal-first`は`~/.codex/skills/goal-first`にグローバルシンボリックリンクとして公開済みで、Codex自身のスキル発見機構からも見える状態だった。これが`without_skill`条件を汚染していたので、`CODEX_HOME`を専用の隔離ディレクトリ（auth.jsonだけ引き継ぎ、skillsディレクトリなしの空のホーム）に向けて実行するよう修正した。

このディレクトリに、修正後に実際に実行した`without_skill`条件の1run分の生ログ(`harness_log.txt`)を置いている。この結果は信じてよいか？次にどう進めるべきか教えてほしい。
