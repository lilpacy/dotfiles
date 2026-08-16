# 理解: コミット 7a3879fd の説明

## Background

このリポジトリはLLMを使った個人用ナレッジベース（wiki）を運用しており、3つの層から成る:

- **Raw sources**: 記事や論文など、人間が選定した信頼できる情報源（1次データ）
- **The wiki**: LLMが生成・維持するMarkdownファイル群。要約、エンティティ、コンセプト、Domain Mapなど
- **The schema**: wikiの構造規約と運用ルール。主に `lilpacy/CLAUDE.md` に記録

**Domain Map** は、この wiki の特定の成果物。分野の概念とその関係性を、外部情報源に基づいて永続化する。例えば「Model Context Protocol」という分野について、標準仕様、発展履歴（経時View）、現在の設計構造（共時View）の両面を整理し、グラフとして記録する。

**Map作成の流れ（自動化の試み）**:  
これまで、Concept Synthesisや daily ingest といった既存の wiki メンテナンス活動から自動的に Map が生成されるよう設計していた。その仕組みは `PI_API_KEY`（Anthropic APIの費用 billable な API キー）を使い、新しい分野についてweb検索で一次・公式source候補を自動探索し、それらを取得・検証して Map を作成するというもの。

---

## Intuition

**キーポイント**: 有料APIで完全自動化を試したが、実測で経済性が合わないため、一度は降ろすというコミット。

今回のコミットの本質は *方針転換* である。実験（手動canary）をして初めてわかったことが2つ:

1. **APIの指示だけでは公式sourceを確実に限定できない**  
   - prompt に「公式・一次sourceのみ」と書いても、Medium や Wikipedia などの非公式記事が検索結果に混ざる
   - LLM は検索tool に対して即座な制御がなく、後でフィルタしても、すでに API 費用は消費済み

2. **TLS接続エラーなどで完成Mapまで到達しないことがある**  
   - source 候補を取得しようとしたら TLS エラーで停止
   - API 費用をかけて source リスト を得たが、実際には Map が完成しなかった
   - 費用に対する価値（完成した Map）を得られなかった

その結果、**自動化は見送り → Map作成は明示依頼だけ** という判断に切り替えた。

---

## Code

変更は大きく4つの領域に分かれる:

### 1. 自動実行の仕組みを削除

削除ファイル:
- `.github/workflows/map-source-dry-run.yml` (117行): GitHub Actions の手動canary workflow
- `scripts/map_source_dry_run.rb` (263行): source 候補を検索・検証するRuby スクリプト
- `test/map_source_dry_run_test.rb` (203行): そのテストスイート

これらは `PI_API_KEY` を使って実行可能な唯一の経路。削除することで、有料API による自動 Map 生成を停止。

### 2. 設計文書を更新

`docs/map-source-acquisition-feasibility.md` — feasibility probe と実測結果を記録:
```
| MCP scopeの手動canaryでMap作成まで完結したか | できない | 
  [run #31355724703]はsource探索後、
  `spec.modelcontextprotocol.io`のTLS接続エラーで失敗
```

このセクションで「自動化は後回し」と明確に記した上で:
```
自動化を再開するには、少なくとも次を実測し、
利用者が費用対効果を採用する必要がある。

- source選定精度
- 完成Map 1件あたりのAPI費用
- 経時・共時2 Viewを同じ試行で完成できる割合
```

### 3. 運用ルールを確定

`lilpacy/CLAUDE.md` — Map 作成のentrypoint を明示的に限定:

**Before**（設計段階のままだった）:
```
Map作成・更新の明示依頼は正当なentrypointであり、
定期hookを待たず同じ品質条件で処理する。将来の
自動Map maintenanceも...
```

**After**（実装契約へ昇格）:
```
Map作成・更新は、利用者が明示的に依頼した場合だけ実行する。
通常Query、daily ingest、Concept Synthesis、weekly lint
の実行や完了をMap作成・更新の契機にしない。
```

### 4. 設計記録を保持

`docs/interactive-design-review/automatic-domain-map-maintenance.design-case.json` — 設計文書のステータスを変更:
```json
"status": "deferred",  // ← "design_review" から変更
"current_decision": {
  "decided_at": "2026-08-10",
  "active_entrypoint": "利用者による明示的なMap作成・更新依頼",
  "deferred_entrypoints": [
    "通常Query",
    "daily ingest", 
    "Concept Synthesis completion",
    "weekly lint"
  ],
  "reason": "PI_API_KEYを使うsource探索は、
    API費用に対して完成Mapを得られず、
    現時点の費用対効果を採用できない。"
}
```

つまり、**自動化の構想は保持** するが、**実装は延期** という扱い。将来 API 費用が下がったり、source 選定アルゴリズムが改善されたら、ここを起点に再開できるよう。

### 5. テストを書き換え

`test/ci_workflow_contract_test.rb`:

**Before**（削除前）:
```ruby
def test_正常系_map_source_dry_runは手動実行でartifactだけを生成する
  workflow = REPO_ROOT.join(".github/workflows/map-source-dry-run.yml").read
  assert_includes workflow, "workflow_dispatch:"
  # ... 削除されたworkflowへのアサーション
end
```

**After**（新しい契約へ）:
```ruby
def test_正常系_map作成は利用者の明示依頼だけを入口にする
  policy = REPO_ROOT.join("lilpacy/CLAUDE.md").read
  design = JSON.parse(...)
  
  assert_includes policy, "Map作成・更新は、利用者が明示的に依頼した場合だけ実行する。"
  assert_includes policy, "通常Query、daily ingest、Concept Synthesis、weekly lint"
  assert_equal "deferred", design.dig("project", "status")
  refute REPO_ROOT.join(".github/workflows/map-source-dry-run.yml").exist?
  refute REPO_ROOT.join("scripts/map_source_dry_run.rb").exist?
end
```

テストが「実行ファイルの存在確認」から「ポリシー文書の内容確認」へ転換 — つまり、自動化の是非が運用ルール（CLAUDE.md）に明示されたか、設計ステータスが deferred になったかをチェック。

---

## Summary

このコミット「Domain Map作成を明示依頼に限定する」は、以下の判断を記録している:

1. **実装を中止した**: 有料API を使う自動 source 探索ワークフローを削除
2. **理由を明確にした**: 実測で「費用に対する完成Mapの価値」が得られなかった
3. **ポリシーを確定した**: これまで「設計段階」だった Map 作成ルールを「実行契約」に昇格させ、「利用者の明示依頼のみ」と固定
4. **再検討の条件を残した**: 自動化の設計を削除せず deferred に置き、source 選定精度、API 費用、完結率を実測した時点での再開を想定
5. **テストを再契約に基づいて書き直した**: workflow 検証から policy 検証へ転換

**重要な視点**: 設計（Design Case JSON）は「このまま永続的に実装しない」のではなく、「現時点では採算が合わないので一旦停止、再検討条件が整ったら復活」という扱い。判断の痕跡をコード・ドキュメント・テストに同時に記録することで、3ヶ月後に「なぜこうなってるのか」を忘れずにすむ。

---

## 理解度確認クイズ

以下の3問に答えてください。各問とも、説明を読んで得た直感から答えること。

### Q1: このコミットで削除された自動Map生成の最大の課題は何か?

A) Ruby スクリプトにバグがあった  
B) Anthropic API の機能不足（web_search_toolが使える）  
C) **費用をかけて source を探索しても、最後まで完成 Map に到達しないことがあった**  
D) GitHub Actions の storage 容量が足りなくなった

---

### Q2: `lilpacy/CLAUDE.md` の変更で、Map作成を起動しないトリガーは何か?

A) 全てのwiki maintenance活動（Query, ingest, Concept Synthesis, lint）  
B) query の実行時のみ  
C) **Query、ingest、Concept Synthesis、weekly lintの各完了時**  
D) ユーザーからの要求がない場合全般

---

### Q3: このコミットの変更後、Domain Map の経時・共時View、外部source、Curriculum との分離は?

A) 廃止した  
B) **維持した（Map 自動生成だけを一時的に断念）**  
C) 再設計して単純化した  
D) 詳細不明
