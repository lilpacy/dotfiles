# コミット 7a3879fd: Domain Map作成を明示依頼に限定する

## Background

Domain Map は lilpacy vault で、特定の概念領域の知識をグラフ構造（ノード・エッジ）で体系化する成果物です。経時・共時の2つのビューで、概念の発展史と現在の構造を記録します。

### 以前の計画
以前、このプロジェクトでは Domain Map の作成を **自動化する**計画がありました。通常の Query や daily ingest、Concept Synthesis、weekly lint などの日常業務の途中で、必要に応じて自動的に Map を生成・更新させるという設計です。実装のために:
- `.github/workflows/map-source-dry-run.yml` という手動実行の canary workflow を用意
- `scripts/map_source_dry_run.rb` で、外部source（ブログ記事、公式ドキュメント、GitHub リポジトリなど）を Anthropic API の web_search tool で検索・取得
- 取得した snapshot から Map を構築する流れ

を準備していました。

### 問題：費用対効果

手動 canary（run #31355724703）を実施した結果、以下の課題が明らかになりました:

| 項目 | 結果 |
|---|---|
| **source 選定精度** | できない。Prompt だけで「一次・公式 source に限定」という指示が機能せず、Medium や Wikipedia など非公式記事も混在 |
| **TLS エラー** | source 探索後、`spec.modelcontextprotocol.io` の TLS 接続に失敗し、snapshot も Map も生成されず |
| **API 費用** | 有料 API (`PI_API_KEY`) を消費したが、完成 Map を得られなかった |

つまり、API 費用の支出に対して、最終的な成果（完成 Map）を得られない状況が発生しました。

---

## Intuition

この判断は **「技術的に可能 ≠ 運用として効率的」** という区別を示しています。

```
従来の計画（自動化）:
  Query / ingest / synthesis実行
      ↓
  (自動trigger)
      ↓
  API で source 探索
      ↓
  (費用消費)
      ↓
  ❌ 接続エラー、source 限定失敗
  → 費用だけ発生、成果なし


新方針（明示依頼）:
  利用者が「Domain Map を作りたい」と明示的に依頼
      ↓
  (判断と責任が明確)
      ↓
  source を検討して取得
      ↓
  Map 完成
  → 成果が確実
```

重要なのは、今後 Map 自動生成を採用するには、**実測値** に基づいて改めて判断することを明記している点です。単に「自動化は難しい」と断定するのではなく、次の3条件が揃えば再検討する、という**再開条件**を定めています:

- source 選定精度が向上したか
- 完成 Map 1件あたりの API 費用
- 経時・共時2つのビューを同じ試行で完成できる割合

---

## Code

### 1. Workflow と Script の削除
`.github/workflows/map-source-dry-run.yml`（117行）と `scripts/map_source_dry_run.rb`（263行）を削除。これらは API 費用をかけて source を検索・取得する実行可能な経路でした。削除することで、意図しない自動実行を防ぎ、利用者の明示依頼による実行だけが可能になります。

### 2. Policy 更新：lilpacy/CLAUDE.md
```
以前:
  Map作成・更新の明示依頼は正当なentrypointであり、定期hookを待たず
  同じ品質条件で処理する。将来の自動Map maintenanceも...

新:
  Map作成・更新は、利用者が明示的に依頼した場合だけ実行する。
  通常Query、daily ingest、Concept Synthesis、weekly lint
  の実行や完了をMap作成・更新の契機にしない。
```

自動 trigger を明示的に **禁止** し、利用者の明示依頼だけを入口に限定しました。

### 3. 設計ドキュメント更新：design-case.json
```json
"status": "deferred",  // design_review → deferred へ変更
"current_decision": {
  "decided_at": "2026-08-10",
  "active_entrypoint": "利用者による明示的なMap作成・更新依頼",
  "deferred_entrypoints": [
    "通常Query",
    "daily ingest",
    "Concept Synthesis completion",
    "weekly lint"
  ],
  "reason": "PI_API_KEYを使うsource探索は、API費用に対して完成Mapを得られず",
  "resumption_condition": "source選定精度、完成Map 1件あたりの費用、経時・共時2 Viewの完結率を実測し..."
}
```

設計の状態を「検討中」から「保留」へ。同時に、保留理由と再開条件を明記することで、将来の意思決定時に **どのデータを測るべきか** を記録しています。

### 4. Feasibility ドキュメント更新
`.md` ファイルに手動 canary（run #31355724703）での実測結果を記録。特に「TLS エラーで失敗」という具体的な障害と、「source 選定精度ができない」という定性的な結果を残しています。

### 5. ログ記録：lilpacy/log.md
```
## [2026-08-10] ops | 有料APIによるDomain Map自動生成を保留

- 更新: `CLAUDE.md` — Map作成・更新のentrypointを利用者の明示依頼だけに限定...
- 削除: `.github/workflows/map-source-dry-run.yml`, `scripts/map_source_dry_run.rb`
- 判断: Domain Mapの経時・共時View、外部source、Curriculumとの分離は維持し、
        Map自動生成だけを一時的に断念する。
```

意思決定を時系列で記録することで、将来「なぜこの判断をしたのか」を辿れるようにしています。

### 6. テスト契約の変更：ci_workflow_contract_test.rb

**削除**:
```ruby
def test_正常系_map_source_dry_runは手動実行でartifactだけを生成する
  workflow = REPO_ROOT.join(".github/workflows/map-source-dry-run.yml").read
  ...
end
```

**新規**:
```ruby
def test_正常系_map作成は利用者の明示依頼だけを入口にする
  policy = REPO_ROOT.join("lilpacy/CLAUDE.md").read
  design = JSON.parse(REPO_ROOT.join("docs/.../automatic-domain-map-maintenance.design-case.json").read)
  
  assert_includes policy, "Map作成・更新は、利用者が明示的に依頼した場合だけ実行する。"
  assert_includes policy, "通常Query、daily ingest、Concept Synthesis、weekly lint"
  assert_equal "deferred", design.dig("project", "status")
  refute REPO_ROOT.join(".github/workflows/map-source-dry-run.yml").exist?
  refute REPO_ROOT.join("scripts/map_source_dry_run.rb").exist?
end
```

テスト契約そのものが「自動 workflow の存在と動作」から「Policy と設計が明示依頼のみを記述し、workflow ファイルが存在しない」という状態に変更されています。これは実装の検証ではなく、**意思決定の確認テスト**になりました。

---

## Quiz

以下のクイズで理解を確認します。

**Q1.** このコミットが削除した `map-source-dry-run.yml` workflow は何を目的としていたのか？

A. Domain Map を定期的に自動生成し、新しい source を常に反映させる  
B. 利用者が手動で実行して、指定した scope と domain/path root に基づいて source 候補を検索・取得し、artifact へ保存する canary  
C. Concept Synthesis の完了時に自動的に呼ばれて、Map を生成する

**正答**: B。workflow は `workflow_dispatch:` で手動実行専用であり、source 検索の feasibility を検証する実験的な workflow でした。

**Q2.** 手動 canary の実測で、以下 3 つのうち「成功した」のはどれか？

| 項目 | 実測結果 |
|---|---|
| source 選定精度（prompt だけで一次・公式に限定） | ❌ できない |
| 選択済み source をセキュアに取得（TLS、redirect制御） | ✅ できる |
| TLS 接続してすべての candidate を取得 | ❌ できない（エラー） |
| content-addressed hash を作成 | ✅ できる |

正答: 「選択済み source をセキアに取得」「hash を作成」。つまり、**既知で安全な source に対する取得は可能だが、自動探索と完全な取得に失敗した**ことが重要。

**Q3.** 新方針で Map 作成・更新を「利用者の明示依頼だけ」に限定した理由は何か？

A. API が悪いから使うなという開発者からのフィードバック  
B. API 費用の支出が確実だが、完成 Map が保証されず、費用対効果が確認できなかったから  
C. 自動化は複雑すぎるので、簡素性のために設計を単純化した

**正答**: B。CLAUDE.md の記述：「API費用に対する完成Mapの価値を得られなかった」。これは技術的限界ではなく、**運用コストと成果のバランス**という経営判断です。

**Q4.** 再開条件として記録された 3 つの実測項目は何か？

A. source 選定精度、完成Map 1件あたりのAPI費用、経時・共時2 Viewの完結率  
B. source 数、取得時間、API response token数  
C. Domain Map の正確性、カバレッジ、ユーザー満足度

**正答**: A。これらは「自動化を採用してもいいのか」を判断するための具体的なメトリクス。単なる技術指標ではなく、費用と成果を天秤にかけるための **意思決定データ**です。

**Q5.** テスト `test_正常系_map作成は利用者の明示依頼だけを入口にする` が検証する内容は？

A. workflow ファイルが完全に機能すること  
B. Policy 文書が「利用者の明示依頼だけ」を明記し、設計ステータスが「deferred」であり、workflow・script ファイルが存在しないこと  
C. API 呼び出し時にエラーハンドリングが正しく機能すること

**正答**: B。このテストは実装の動作検証ではなく、**意思決定と文書の一貫性** を確認する契約テストです。

---

## まとめ

このコミットは、Domain Map 自動生成の実験的な実装を **完全に削除**し、代わりに **利用者の明示依頼だけを受け入れる**という方針転換を記録しています。

重要な特徴:

1. **単なる削除ではなく、判断の記録**: 再開条件を明確に文書化し、将来の改めての検討時に何を測るべきか示している
2. **費用対効果の区別**: 技術的に可能でも、運用として効率的でない場合の決定方法を示した
3. **段階的な保留**: 完全に放棄するのではなく、条件が整えば再開する可能性を残している
4. **テスト契約の更新**: 実装テストから意思決定テストへの転換

このアプローチは、**失敗を学習に変える**ことの良い例になっています。
