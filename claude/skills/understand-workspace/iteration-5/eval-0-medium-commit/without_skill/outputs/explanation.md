# コミット 7a3879fd「fix: Domain Map作成を明示依頼に限定する」の内容

## 一行でいうと

有料 API（`PI_API_KEY`）を使って Domain Map を自動生成しようという進行中の試みを、費用対効果が確認できないという実測にもとづいて**中止（保留）し、Map の作成・更新は利用者が明示的に依頼したときだけ行う**という契約に戻したコミットです。コードを直すバグ修正ではなく、**方針転換をリポジトリの実行契約・設計記録・テストに反映させた**変更です。

8 ファイル、53 行追加 / 616 行削除。差分の大半は削除です。

## 背景：直前に何が起きていたか

git log を見ると、このコミットの直前まで自動化の実証（feasibility spike）が進んでいました。

- `de1c5615` (PR #70): Map source 取得経路の実測（`ee07d34b` 検索経路、`3f198a1b` 取得境界、`782c2b95` 結果記録）
- `32b86796` (PR #71): 手動 dry-run workflow の追加（`af107ef4`）と取得境界の締め込み（`58c29305`）
- そして `7a3879fd`：**その dry-run 経路を削除**

つまり「作ったばかりの実験用経路を、実測結果を受けて自分で撤去した」コミットです。

決め手になった実測は 2 つです。

1. **source 選定が prompt だけでは絞れない**。公式・一次 source に限定するよう指示しても、18 URL 中に Medium・Wikipedia・解説記事が混在し、API 応答も `stop_reason: max_tokens` で打ち切られた。
2. **手動 canary が Map 作成まで到達しなかった**。[run #31355724703](https://github.com/lilpacy/obsidian/actions/runs/31355724703) は有料 API での source 探索を終えたあと、`spec.modelcontextprotocol.io` の TLS 接続エラーで停止し、snapshot artifact も Map も生成しなかった。

有料 API のコストは払ったのに成果物（完成 Map）がゼロ、という結果です。

## 実際の変更内容

### 1. 実行可能な自動化経路の削除

- `.github/workflows/map-source-dry-run.yml`（117 行）を削除
- `scripts/map_source_dry_run.rb`（263 行）を削除
- `test/map_source_dry_run_test.rb`（203 行）を削除

`PI_API_KEY` を使って外部 source を探索できるコードを、リポジトリから物理的に無くしました。「使わない方針にした」だけでなく「動かせる状態を残さない」という徹底の仕方です。

### 2. 運用契約（`lilpacy/CLAUDE.md`）の書き換え

これがこのコミットの中心です。変更前は将来の自動化を前提にした書き方でした（「自動 Map maintenance も…Concept Synthesis 完了後に起動する独立 workflow とし」「自動 workflow はまだ未実装である」）。変更後はこうなっています。

> Map作成・更新は、利用者が明示的に依頼した場合だけ実行する。通常Query、daily ingest、Concept Synthesis、weekly lint の実行や完了をMap作成・更新の契機にしない。`PI_API_KEY`を使う有料APIでのsource探索・Map自動生成は、費用対効果が確認できるまで保留し、workflowを置かない。

「未実装」から「置かない」への変更であり、エントリポイントを 4 つ（通常 Query / daily ingest / Concept Synthesis 完了 / weekly lint）明示的に閉じています。あわせて workflow 一覧から `map-source-dry-run.yml` の記述も削除。

### 3. 設計記録（design case JSON）の状態遷移

`docs/interactive-design-review/automatic-domain-map-maintenance.design-case.json` で `status` を `design_review` → `deferred` に変更し、`current_decision` ブロックを新設しました。

| フィールド | 内容 |
|---|---|
| `active_entrypoint` | 利用者による明示的な Map 作成・更新依頼 |
| `deferred_entrypoints` | 通常 Query / daily ingest / Concept Synthesis completion / weekly lint |
| `reason` | API 費用に対して完成 Map を得られず、現時点の費用対効果を採用できない |
| `resumption_condition` | source 選定精度、完成 Map 1 件あたりの費用、経時・共時 2 View の完結率を実測して再判断 |
| `history_note` | 以下の自動 maintenance 設計は再検討時の履歴として保持するが、現在の実行契約ではない |

注目すべきは `success_conditions` 以下の元の設計記述を**消していない**点です。「履歴として残すが現在の契約ではない」と明示的にラベルを貼って共存させています。

### 4. feasibility ドキュメントの結論の書き換え

`docs/map-source-acquisition-feasibility.md` の性格が変わりました。

- 冒頭の結論が「技術的に成立するから、こう分離して実装する」から「**技術的に成立することと、運用として効率的であることは別である**」に差し替え
- 実測表に canary 失敗の行を追加
- セクション名「採用する境界」→「**将来再検討する場合にも必要な境界**」（取得境界の知見は捨てず、稼働中 pipeline ではないと明記）
- セクション名「未解決」→「**再開条件**」。再開に必要な実測指標を 3 つ列挙（source 選定精度 / 完成 Map 1 件あたりの API 費用 / 経時・共時 2 View を同じ試行で完成できる割合）

### 5. テストを「workflow の形」から「方針の文言」へ

`test/ci_workflow_contract_test.rb` のテストを差し替えました。

- 旧: `test_正常系_map_source_dry_runは手動実行でartifactだけを生成する` — YAML 内の `workflow_dispatch:`、`--proto '=https'`、`--max-filesize` などの実装詳細を検証
- 新: `test_正常系_map作成は利用者の明示依頼だけを入口にする` — `lilpacy/CLAUDE.md` に方針文が含まれること、design case の `status` が `deferred` で `active_entrypoint` が明示依頼であること、そして削除した 2 ファイルが**存在しないこと**（`refute ... .exist?`）を検証

つまり CI が「自動化経路が復活していないこと」を守り続ける形になっています。ここが単なる文書更新と決定的に違う点で、方針が**テストで強制される**ようになりました。

### 6. log.md への追記

`lilpacy/log.md` に `## [2026-08-10] ops | 有料APIによるDomain Map自動生成を保留` エントリを追加。更新・削除・判断を 4 行で記録し、最後にスコープの限定を明言しています。

> 判断: Domain Mapの経時・共時View、外部source、Curriculumとの分離は維持し、Map自動生成だけを一時的に断念する。

## このコミットの設計上の要点

**捨てたものと残したものが明確に分かれています。** 捨てたのは「有料 API で source を探索して Map を自動生成する実行経路」だけ。Domain Map そのものの概念、経時・共時の 2 View、取得境界（HTTPS 限定・redirect 5 回・1 MiB 上限など）、Curriculum との分離といった設計知見は全て保持されています。

**「保留」が空約束になっていません。** deferred と書くだけなら誰でもできますが、ここでは (a) 再開条件を測定可能な 3 指標として定義し、(b) 履歴を `history_note` 付きで保存し、(c) 復活していないことを CI テストで検証しています。将来の自分（あるいは将来の LLM エージェント）が「なぜ自動化しなかったのか」「どうなったら再開していいのか」を差分を掘らずに読めます。

**コミットメッセージの `fix:` は「壊れたコードの修正」ではなく「実行契約の是正」の意味です。** 実測を根拠に方針を狭めた、という位置づけです。AGENTS.md にある「推測するな計測せよ」の実践例そのもので、技術的に可能（feasible）だと確認できた直後に、運用的に見合わない（not worth it）と判断して引き返しています。
