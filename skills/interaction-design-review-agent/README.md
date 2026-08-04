# Interaction Design Review Agent Skill

設計プロセスを、会話とステージゲートで最後まで支援するAgent Skillです。

## 位置づけ

旧版 `interaction-design-decision-coach` は、設計判断を一問ずつ整理する「コーチ」に重点がありました。  
本版は、その考え方を次の**レビュー・パイプライン**へ拡張しています。

```mermaid
flowchart LR
    A[Business Workflow]
    B[Decision Flow]
    C[Decision Table]
    D[Design Principles]
    E[Contradiction Checker]
    F[State Machine]
    G[Information Architecture]
    H[UI Behavior]

    A --> B --> C --> D --> E --> F --> G --> H
```

## 旧版からの主な強化

| 項目 | 旧版 | 本版 |
|---|---|---|
| 対話 | 一問ずつ支援 | 一問ずつ＋質問優先順位 |
| 状態保持 | 設計状態JSON | パイプライン状態・証拠・追跡関係を追加 |
| 工程管理 | 推奨順序 | 明示的なステージゲート |
| 矛盾 | 監査ルール | Blocking時に下流工程を停止 |
| 成果物 | 状態・IA・UI | 全工程の出力契約 |
| 実行補助 | 構造検査 | 検証、ゲート判定、次質問選択、移行 |
| 評価 | テストケース | 正常・不足・矛盾のfixtureと自動テスト |

## フォルダ構成

```text
interaction-design-review-agent/
├── SKILL.md
├── README.md
├── MIGRATION.md
├── VALIDATION.md
├── references/
│   ├── process-model.md
│   ├── stage-gates.md
│   ├── dialogue-protocol.md
│   ├── contradiction-catalog.md
│   ├── traceability.md
│   ├── output-contracts.md
│   └── worked-example-anime-generation.md
├── assets/
│   ├── design-case.template.json
│   ├── design-case.schema.json
│   ├── pipeline-definition.json
│   ├── decision-table.template.md
│   └── review-report.template.md
├── scripts/
│   ├── validate_design_case.py
│   ├── review_pipeline.py
│   ├── next_question.py
│   ├── migrate_v0_1_state.py
│   └── example_design_case.json
├── evals/
│   ├── test-cases.md
│   └── fixtures/
└── tests/
    └── test_scripts.py
```

## 使い始める指示例

```text
interaction-design-review-agentを使って、この設計をBusiness Workflowから対話形式で整理してください。
既知情報を先に抽出し、一度に1問だけ質問してください。
Blocking矛盾がある間は、State Machine以降へ進まないでください。
```

途中から監査する場合：

```text
この設計案を現在のステージから復元し、パイプラインのどこにいるか判定してください。
Blocking矛盾と、次に答えるべき1問だけを示してください。
```

## ローカル検証

```bash
python3 scripts/validate_design_case.py scripts/example_design_case.json
python3 scripts/review_pipeline.py scripts/example_design_case.json
python3 scripts/next_question.py evals/fixtures/incomplete-case.json
python3 -m unittest tests/test_scripts.py
```

外部ライブラリは不要です。
