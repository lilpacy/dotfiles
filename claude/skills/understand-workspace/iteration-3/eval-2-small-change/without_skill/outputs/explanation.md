# コミット `e4f5325f` の説明

## 結論

作業用の実装計画ファイルを1本消しただけの後片付けコミットです。vault（`lilpacy/`）の内容やパイプラインの挙動には一切影響しません。

```
e4f5325f chore: 中間生成物の実装計画を削除
Author: lilpacy <revivedtomorrow@gmail.com>
Date:   Sun Aug 16 07:10:30 2026 +0900

 docs/superpowers/plans/2026-08-16-development-process-artifacts.md | 78 ------
 1 file changed, 78 deletions(-)
```

削除のみ。追加行・変更行はゼロです。

## 削除されたファイルは何だったか

`docs/superpowers/plans/2026-08-16-development-process-artifacts.md` は、`lilpacy/concepts/ソフトウェア開発プロセス.md` を「工程名の羅列」から「いつ・何を確定し・どの成果物として次工程へ渡すか」が分かる正本へ更新するための実装計画でした。superpowers 系ワークフローで作業前に書く計画ドキュメントで、内容は次のようなものです。

- 変更範囲: `concepts/ソフトウェア開発プロセス.md` の `inputs` に3本の summary を追加し、開発フロー全体の Mermaid に概念設計・ドメイン設計の起動条件と戻り先を統合、その直後に工程別成果物表を配置。あわせて `index.md` の1行説明と `log.md` の追記。
- 工程別成果物の設計: 企画・構想から運用・保守・改善までの11工程について「この工程で確定すること / 代表成果物 / 次工程へ渡す状態」を対応づける表の仕様。
- 成果物の精緻化系列: 課題→要件→テストケース→テスト結果、概念データモデル→論理→物理→migration など5系列を Mermaid で示す方針。
- 新規 claim の根拠表: 各 claim に2つ以上の独立 source lineage（summary の組み合わせ）を明示。
- 検証手順: `ruby scripts/wiki_pipeline_lint.rb .`、`git diff --check`、lineage の目視確認、commit 後の read-only Codex review、push と PR 作成。

## なぜ消したのか（コミット履歴からの流れ）

この計画ファイルは同じ作業ブランチ `worktree/quiet-field-6595` の中で生まれて死んでいます。

| commit | 内容 | 計画ファイル |
|---|---|---|
| `2a53eb61` docs: 開発工程と成果物の対応を整理 | 計画作成 + vault 更新 | 追加（80行） |
| `6818a609` fix: 概念設計とドメイン設計を全体フローへ統合 | 分岐の見直し | 更新 |
| `5ecee513` fix: 開発フロー分岐と成果物表を条件付き活動として整合 | 自己ループ修正など | 更新 |
| `e4f5325f` chore: 中間生成物の実装計画を削除 | 後片付け | **削除** |

つまり計画に沿った実装（`concepts/ソフトウェア開発プロセス.md`、`index.md`、`log.md` の更新）が終わり、レビュー指摘に応じた2回の修正まで済んだ段階で、役目を終えた足場を畳んだ、という位置づけです。コミットメッセージの「中間生成物」がまさにそれを言っています。作業の記録自体は `lilpacy/log.md` の `2026-08-16` エントリ側に残るので、計画ファイルを残す必要がない、という判断だと読めます。

この削除の8分後（07:18）に PR #86 がマージされており、その結果 main に入ったのは vault の3ファイルだけです。

```
1676174f Merge pull request #86 ... docs: 開発工程と成果物の対応を整理
 lilpacy/concepts/ソフトウェア開発プロセス.md | 91 ++++++++++++-----
 lilpacy/index.md                             |  2 +-
 lilpacy/log.md                               | 25 +++++++
```

`e4f5325f` は main に取り込まれており（`git merge-base --is-ancestor` で確認）、この計画ファイルは main の履歴上に一度も「存在した状態」で現れません。ブランチ内で完結して消えたためです。

## 現在のリポジトリ状態

`docs/superpowers/` に残っているのは 2026-07-21 の query-ingest 関連2本のみです。

- `docs/superpowers/plans/2026-07-21-query-ingest.md`
- `docs/superpowers/specs/2026-07-21-query-ingest-design.md`

`lilpacy/concepts/ソフトウェア開発プロセス.md` は計画の成果として更新済みの状態で main にあります。

## 気をつけるとよい点

計画ドキュメントの扱いが一貫していません。2026-07-21 の query-ingest は plan と spec を残しているのに、今回は消しています。「計画は成果物に反映されたら消す」のか「設計判断の記録として残す」のかがルール化されていないので、後から履歴を追う人が `docs/superpowers/plans/` を見ても、そこにあるものが全部なのか一部なのか判断できません。方針を `AGENTS.md` か `lilpacy/CLAUDE.md` に一文書いておくと、今後の superpowers 系作業で迷わなくなります。

なお今回の削除自体で失われた情報はほぼありません。計画の要点（工程別成果物表、精緻化系列、起動条件）はすべて更新後の `concepts/ソフトウェア開発プロセス.md` 側に載っており、必要なら `git show 2a53eb61:docs/superpowers/plans/2026-08-16-development-process-artifacts.md` で全文を復元できます。
