# コミット 7a3879fd の理解説明

## Background（背景）

このコミットを理解するには、まず Domain Map 自動化の試行背景を押さえる必要があります。

このリポジトリは `lilpacy/` という個人向け知識ベース（LLM Wiki）を運用しており、その中心の一つが「Domain Map」です。Domain Map とは、ある分野（例：Model Context Protocol）の概念構造を時間軸（経時：diachronic）と現在の全体像（共時：synchronic）で可視化したネットワークグラフです。

これまで Domain Map の作成・更新は、ユーザーが明示的に依頼するたびに手動で行われていました。しかし、より効率的な運用を目指して、**定期的なジョブ（daily ingest、weekly lint、Concept Synthesis など）の完了後に自動的に Map を生成する仕組みを導入しようという試み**が並行して進んでいました。

コミット `f8d3d208` の約4週間前（コミット `af107ef4`）に「Map source 手動 dry-run」という GitHub Actions ワークフローが追加されていました。これは `PI_API_KEY`（Anthropic の有料 API キー）を使い、指定した分野について web search ツールで公式 source を自動探索し、それらを content-addressed snapshot として保存するワークフローでした。このワークフローが成功し、実装が可能だと実証されれば、完全な自動 Map 生成へ進む予定でした。

## 実測と失敗

直前のコミット `32b86796`（merge commit）で、このワークフローの feasibility probe（技術実現可能性の検証）が GitHub Actions 上で実行されました。結果は技術的には部分的に成立しましたが、**費用対効果が成立しませんでした**。

具体的には：

- ✅ Web search による source 候補の抽出：成功
- ✅ HTTPS 限定で snapshot を取得：成功  
- ✅ SHA-256 ハッシュを計算：成功
- ❌ **最後まで完結して Map を生成：失敗**

手動 canary run（`run #31355724703`）の実行結果、`spec.modelcontextprotocol.io` への TLS 接続エラーが発生し、snapshot artifact も生成されず、Map の作成には至りませんでした。つまり、**有料 API を消費して source を探索しても、最後のステップで失敗し、完成した Map を得られなかった**のです。

## Intuition（核となる決定）

このコミットは、その試行を**一時的に中止する決定を実行するもの**です。

```
試行開始（af107ef4）
    ↓
feasibility 検証（含 probe / canary）
    ↓
技術: できる（TLS接続など部分的にはクリア）
費用対効果: 成立しない
    ↓
[このコミット]
    ↓
自動化の保留・削除
利用者による明示依頼だけを再度メインの入口に
再開条件を記録して保留
```

重要な点は、**技術的にできるかどうか** vs **運用として効率的か（費用対効果が取れるか）** という判断軸の転換です。LLM Wiki の設計思想では、AI を使った複利的な知識蓄積を目指していますが、今回は「無条件に自動化する」のではなく「実測に基づいて採用判断する」という慎重さが優先されました。

## Code（変更の実装）

コミットは以下の構成で成立しています：

### 1. 実行可能なワークフローとスクリプトを削除

```
削除:
- .github/workflows/map-source-dry-run.yml (117行)
- scripts/map_source_dry_run.rb (263行)
- test/map_source_dry_run_test.rb (203行)
```

`.github/workflows/map-source-dry-run.yml` は手動実行（`workflow_dispatch`）で、スコープと公式 source root を入力して web search ベースの source 探索を行い、artifact として candidate を保存するワークフローでした。これが完全に削除されました。

### 2. 設計ドキュメントを更新：現状を記録

**`docs/interactive-design-review/automatic-domain-map-maintenance.design-case.json`** では、プロジェクト status を `design_review` → `deferred` に変更し、新しく `current_decision` セクションを追加：

```json
"current_decision": {
  "decided_at": "2026-08-10",
  "active_entrypoint": "利用者による明示的なMap作成・更新依頼",
  "deferred_entrypoints": [
    "通常Query",
    "daily ingest", 
    "Concept Synthesis completion",
    "weekly lint"
  ],
  "reason": "PI_API_KEYを使うsource探索は、API費用に対して完成Mapを得られず、現時点の費用対効果を採用できない。",
  "resumption_condition": "source選定精度、完成Map 1件あたりの費用、経時・共時2 Viewの完結率を実測し、新しい意思決定として自動化を採用する。"
}
```

この記録により、**なぜ保留したのか**、**どういう条件が揃ったら再開するのか** が明示されます。

**`docs/map-source-acquisition-feasibility.md`** では、dry-run の失敗を記録。元の設計では「自動化の前提と検討事項」が書かれていたのに対し、今回は：

- 技術的実現可能性とは別に、運用効率を優先する判断
- 2026-08-10 の実測で TLS エラーが完成を阻止した
- prompt だけでの source 限定も失敗している
- **再開には 3 つの実測が必要** という条件を記録

### 3. 運用ルール（CLAUDE.md）を更新

`lilpacy/CLAUDE.md` の Map 関連セクションから、自動化に関する記述を削除し、以下に置き換え：

```markdown
Map作成・更新は、利用者が明示的に依頼した場合だけ実行する。通常Query、daily ingest、
Concept Synthesis、weekly lint の実行や完了をMap作成・更新の契機にしない。
```

つまり、daily ingest など既存の定期ジョブが走っても、その完了をきっかけに Map が自動生成されることはもうない、ということが契約化されました。

### 4. テストの更新

古い `map_source_dry_run_test.rb` （203行）は完全に削除。

`ci_workflow_contract_test.rb` では、旧テスト名 `test_正常系_map_source_dry_runは手動実行でartifactだけを生成する` が削除され、新テスト `test_正常系_map作成は利用者の明示依頼だけを入口にする` に置き換わっています。新テストは：

```ruby
policy = REPO_ROOT.join("lilpacy/CLAUDE.md").read
design = JSON.parse(REPO_ROOT.join("docs/interactive-design-review/automatic-domain-map-maintenance.design-case.json").read)

assert_includes policy, "Map作成・更新は、利用者が明示的に依頼した場合だけ実行する。"
assert_includes policy, "通常Query、daily ingest、Concept Synthesis、weekly lint"
assert_equal "deferred", design.dig("project", "status")
assert_equal "利用者による明示的なMap作成・更新依頼", design.dig("project", "current_decision", "active_entrypoint")
refute REPO_ROOT.join(".github/workflows/map-source-dry-run.yml").exist?
refute REPO_ROOT.join("scripts/map_source_dry_run.rb").exist?
```

つまり、テストレベルでも「実行可能なワークフローが存在しない」「運用ルールに『明示依頼だけ』と明記されている」を確認する **契約テスト** になりました。

### 5. ログに判断記録

`lilpacy/log.md` に追記専用で記録：

```
## [2026-08-10] ops | 有料APIによるDomain Map自動生成を保留
```

新しい entrypoint は試行されていないので、これまでの設計は削除されず、**将来の再検討用に保持**されています。

## Quiz（理解確認）

以下の3問に答えて、理解度を確認しましょう。

### 問1：このコミットが削除した最大の成果物は何か？

A. Domain Map 自動生成の完全な実装
B. 有料 API による source 探索と snapshot 取得を行う実行可能なワークフロー
C. Map 作成に使う web search ツールのプラグイン
D. Source 探索の prompt テンプレート

**正解：B**

費用対効果が取れないと判断されたため、実際に GitHub Actions で走っていた `map-source-dry-run.yml` ワークフロー（117行）が削除されました。これまでのテスト実行では partial success（部分的な成功）がありましたが、完成する前に TLS エラーで止まるため、有料 API の消費を正当化できませんでした。

---

### 問2：なぜこの削除後も、設計ドキュメント（`automatic-domain-map-maintenance.design-case.json`）は完全に削除されず、status が「deferred」に変わったのか？

A. 将来的に自動化を再開したい場合、再度実装するときの参考にするため
B. 過去の試行結果を保存して外部に報告する義務があるため
C. 自動化が「失敗」ではなく「保留」であることを示し、再開条件を記録するため
D. GitHub のアーカイブ要件に従うため

**正解：C**

このコミットは単なる「失敗プロジェクトの削除」ではなく、**意思決定の記録**です。`current_decision` セクションに：
- 何を決めたか（自動化を保留）
- なぜか（費用対効果が現在成立しない）
- どの条件が揃ったら再考するか（source 選定精度、完成 1 件あたりの費用、2 View 完結率の実測）

が記録されています。これにより、1年後に「Domain Map を自動化しよう」と誰かが思ったとき、同じ失敗を繰り返さず、「あ、2026年に試したが費用対効果が課題だった」と参照できます。

---

### 問3：このコミット後、daily ingest や weekly lint が実行されても Map は生成されなくなった。では、ユーザーが Domain Map を作成・更新したい場合、現在どうやって依頼する？

A. GitHub Issues でリクエストを作成する
B. このコミットで削除されたため、現在のところ実装されていない
C. 別途用意された「Map 作成依頼用ワークフロー」で `workflow_dispatch` で手動実行する
D. Slack bot に依頼する

**正解：B**

運用ルールは「Map 作成・更新は利用者の明示依頼時だけ」と定義されましたが、このコミット内には「その依頼をどう受け付けるか」の実装は含まれていません。`map-source-dry-run.yml` は手動 dry-run 用であり、最終的な Map 生成はまだ設計段階です。つまり、現在のところ**利用者による明示依頼の仕組みそのものが、まだ実装されていない**状態です。これは次の iteraction で実装される予定と考えられます。

---

この規模の変更（実装から設計判断の記録への転換）では、設計や意思決定プロセスが「最後はうまくいく」という前提を疑い、**実測に基づいた判断ができるか** を読者が理解しているかが重要です。技術的には成立しても、運用効率が取れなければ採用しない—これは成熟した判断軸です。
