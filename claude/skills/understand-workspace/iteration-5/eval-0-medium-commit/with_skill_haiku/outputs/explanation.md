# Commit 7a3879fd: Domain Map作成を明示依頼に限定する

## TL;DR

- **目的**: Domain Map の自動生成を一時的に保留し、利用者の明示依頼時だけに限定する
- **背景**: 有料APIによるsource探索の手動canaryが失敗し、費用対効果が合わない
- **削除**: 自動化に向けた3つの成果物
  - GitHub Actions workflow（map-source-dry-run.yml）
  - Ruby script（map_source_dry_run.rb）
  - 専用テスト（map_source_dry_run_test.rb）
- **更新**: ポリシー文書と設計ケースに、保留の理由と再開条件を明示的に記録
- **判断**: Map構造（経時・共時View、外部source）は維持し、自動生成だけを断念

---

## Background（why）

このプロジェクトは **LLM Wiki** アーキテクチャを採用している。raw source → wiki ページ → スキーマの3層構造を持ち、Concept Synthesis や Domain Map のような高度な知識表現は、これまで手動で作成されていた。

2026年8月に **自動化の実験** が始まった。概要は以下：

1. 検索対象の「scope」と「公式domain」を利用者が指定
2. Anthropic APIの web_search_tool で source を探索
3. TLS接続で候補を取得し、SHA-256で内容をaddress
4. snapshot artifactと manifest を生成

この経路は **feasibility probe** として計測されていた。限定scope（MCP）、限定source（公式domain）、限定リソース（2回検索、1 MiB/source、30秒）で検証が進んでいた。

```
 probe #31333925809 (成功) → 公式domainからの取得は成立
 ↓
 手動canary #31355724703 (失敗) → 途中でTLS接続エラーで停止、
                              Map生成まで到達できず
 ↓
 方針変更の判断
```

コミット時点で、**「有料APIで完成Mapを得られない」という実測**が得られたため、自動化の判断が見直された。

---

## Intuition（what）

このコミットの本質は：**「技術的に成立することと、運用として効率的であることは別」という学習を、ポリシーに明示的に記録する**。

コミット前の状態：
```
既存ポリシー「自動Map maintenanceを実装する計画あり」
    ↓
実験的workflow(map-source-dry-run.yml)は存在
    ↓
でも、まだどこからも起動されていない
    ↓
不完全な中途状態が repo に残存
```

コミット後の状態：
```
新しいポリシー「Map作成は利用者の明示依頼だけ」
    ↓
自動起動する経路は全削除
    ↓
なぜ削除したのか、再開する条件は何かを文書に記録
    ↓
次の誰かが同じ判断を再現できる
```

決定内容：

| 項目 | 変更前 | 変更後 |
|--|--|--|
| Map作成の入口 | 自動化予定（未実装） | **明示依頼だけ** |
| 契機 | Query/ingest/synthesis/lint から起動予定 | これらからは起動しない |
| API使用 | 有料（PI_API_KEY） | 利用しない |
| 対象Workflow | map-source-dry-run.yml が存在 | **削除** |
| 設計ケース status | "design_review" | "deferred" |

**再開条件は明確に規定されている**：
- source選定精度（非公式記事を弾けるか）
- 完成Map 1件あたりのAPI費用
- 経時・共時2 Viewを同じ試行で完成できる割合

この3点を実測して初めて、新しい意思決定として自動化を採用する。

---

## Code（how）

削除・更新の主要部分：

### 1. Workflow・Scriptの削除

**削除ファイル：**
- `.github/workflows/map-source-dry-run.yml` (117行)
  - `workflow_dispatch` で利用者が手動実行
  - Anthropic API呼び出し、source取得、snapshot生成
  - artifact upload
  
- `scripts/map_source_dry_run.rb` (263行)
  - Request生成、Continuation処理、Response merge、Candidate収集
  - Input validation（source root の有効性チェック）
  
- `test/map_source_dry_run_test.rb` (203行)
  - 検索limitの処理、pause_turn継続、source候補の収集テスト

### 2. ポリシー文書の更新

**lilpacy/CLAUDE.md**（抜粋）

```markdown
# 変更前
Map作成・更新の明示依頼は正当なentrypointであり、定期hookを待たず同じ品質条件で処理する。
将来の自動Map maintenanceも既存ingestやConcept Synthesisの責務へ混ぜず、
独立workflowとし、明示経路と同じscope解決・builder・lintへ合流させる。
自動workflowはまだ未実装である。

# 変更後
Map作成・更新は、利用者が明示的に依頼した場合だけ実行する。通常Query、daily ingest、
Concept Synthesis、weekly lintの実行や完了をMap作成・更新の契機にしない。
PI_API_KEYを使う有料APIでのsource探索・Map自動生成は、費用対効果が確認できるまで保留し、
workflowを置かない。自動化を再検討する場合は、source選定精度、完成Map 1件あたりの費用、
経時・共時2 Viewの完結率を実測し、新しい意思決定として明示的に採用する。
```

### 3. 設計ケース（design-case.json）の更新

```json
{
  "status": "deferred",  // 変更前: "design_review"
  "current_decision": {
    "decided_at": "2026-08-10",
    "active_entrypoint": "利用者による明示的なMap作成・更新依頼",
    "deferred_entrypoints": [
      "通常Query",
      "daily ingest",
      "Concept Synthesis completion",
      "weekly lint"
    ],
    "reason": "PI_API_KEYを使うsource探索は、API費用に対して完成Mapを得られず、
               現時点の費用対効果を採用できない。",
    "resumption_condition": "source選定精度、完成Map 1件あたりの費用、
                           経時・共時2 Viewの完結率を実測し、新しい意思決定として
                           自動化を採用する。",
    "history_note": "以下の自動maintenance設計は、再検討時の履歴として保持するが、
                   現在の実行契約ではない。"
  }
}
```

### 4. Feasibility文書の更新

**docs/map-source-acquisition-feasibility.md**（抜粋）

実測結果を表に追加：
```markdown
| MCP scopeの手動canaryでMap作成まで完結したか | できない | 
  [run #31355724703]はsource探索後、spec.modelcontextprotocol.ioのTLS接続エラーで
  失敗し、snapshot artifactもMapも生成しなかった |
```

### 5. テスト の置き換え

**変更前：**
```ruby
def test_正常系_map_source_dry_runは手動実行でartifactだけを生成する
  workflow = REPO_ROOT.join(".github/workflows/map-source-dry-run.yml").read
  assert_includes workflow, "workflow_dispatch:"
  # ...
end
```

**変更後：**
```ruby
def test_正常系_map作成は利用者の明示依頼だけを入口にする
  policy = REPO_ROOT.join("lilpacy/CLAUDE.md").read
  design = JSON.parse(REPO_ROOT.join("docs/.../automatic-domain-map-maintenance.design-case.json").read)
  
  assert_includes policy, "Map作成・更新は、利用者が明示的に依頼した場合だけ実行する。"
  assert_equal "deferred", design.dig("project", "status")
  assert_equal "利用者による明示的なMap作成・更新依頼", design.dig("project", "current_decision", "active_entrypoint")
  refute REPO_ROOT.join(".github/workflows/map-source-dry-run.yml").exist?
end
```

テスト自体が「workflow の存在確認」から「ポリシー の宣言確認」に切り替わり、実装の詳細ではなく**判断の記録**をチェックする形に。

---

## Quiz

この説明を読んだ後、以下の問いに答えてください。

**Q1**: このコミットが削除した workflow の主な用途は何か？
- (A) Domain Map を定期的に自動生成する
- (B) 利用者が手動で source を指定し、候補を探索・取得するcanary実験
- (C) daily ingest 完了時に自動的にsource探索を行う
- (D) litpacy/vaultの synthesis 完了後に自動実行される

**Q2**: 「再開条件」として記録されたものは、どのような指標か？（複数選択可）
- (A) API呼び出し回数を1回以下に制限すること
- (B) source選定精度（非公式記事を弾けるか）
- (C) 完成Map 1件あたりのAPI費用
- (D) 経時・共時2 Viewを同じ試行で完成できる割合
- (E) TLS接続タイムアウトを3秒以下にすること

**Q3**: このコミットが**削除せず、文書として保持した**理由は何か？
- (A) 将来の自動化再検討時に、失敗の経験を参考にするため
- (B) 法的な監査証跡として残す必要があるため
- (C) LLM エージェントの判断追跡を記録するため
- (D) (A)と(C)の両方

**Q4**: テスト（ci_workflow_contract_test.rb）の変更で、何が変わったのか？
- (A) `workflow_dispatch` の確認から、ポリシー文書と設計ケースの確認に切り替わった
- (B) artifact upload の仕様チェックから、API費用指標の確認に切り替わった
- (C) workflow ファイルの存在を確認から、存在しないことを確認に切り替わった
- (D) (A)と(C)の両方

---

## 解答と解説

**Q1: 答え (B)**

- **理由**: workflow ファイルの内容と関連文書から、`workflow_dispatch` で利用者が手動起動し、scope と source を指定すると、API を使って候補探索・取得を行う形。これはcanary（実験）であり、production ではない点が重要。
- **誤答の根拠**:
  - (A) 「定期的に」ではなく「手動」。スケジュール trigger がない
  - (C)(D) 「自動」ではなく、workflow_dispatch は利用者起動

**Q2: 答え (B)(C)(D)**

- **理由**: feasibility 文書と CLAUDE.md に明記された「resumption_condition」が3つの指標。これらを実測して初めて、新しい意思決定として自動化を採用する。
- **誤答の根拠**:
  - (A) 「呼び出し回数を1回以下」ではなく、「2回の searches」が probe の限界設定。再開条件ではない
  - (E) TLS接続エラーが問題だったが、これ自体を「指標」にするのではなく、「source選定精度」という抽象化した条件で解決を見ている

**Q3: 答え (D)**

- **理由**: 
  - (A) 履歴として保持する理由が明記: `history_note: "以下の自動maintenance設計は、再検討時の履歴として保持する"`
  - (C) LLMエージェント視点では、このような「判断の記録」は次のagentが同じ過ちを繰り返さず、より良い判断を下すために不可欠
  - wiki 維持の複利性を見ると、失敗から学んだ「なぜ失敗したのか」の記録こそが資産

**Q4: 答え (D)**

- **理由**:
  - (A) 明示的に切り替わった。test 関数が `test_正常系_map_source_dry_runは手動実行で...` から `test_正常系_map作成は利用者の明示依頼だけを入口にする` に変更
  - (C) `refute REPO_ROOT.join(".github/workflows/map-source-dry-run.yml").exist?` で存在しないことをチェック
- **誤答の根拠**:
  - (B) artifact や費用指標の確認ではなく、「ポリシー宣言」と「ファイル削除の確認」が主眼

---

## 次の一手

1. **コード レビューの視点**：
   - `lilpacy/CLAUDE.md` と `design-case.json` が同期しているか確認する
   - 「再開条件」が実測可能な指標になっているか検証（曖昧性はないか）

2. **運用への影響**：
   - 利用者による明示依頼はどの channel / issue form で行われるのか
   - 明示依頼時の「品質条件」（Map completeness、source diversity など）は何か

3. **今後の実験**：
   - 再開条件の3指標を実測するための実験計画の有無確認
   - 現在、どの指標が観測可能か、どの指標がまだブラックボックスか

---

**この規模の変更なので、このレベルの説明で十分です。クイズで理解を確認してください。**
