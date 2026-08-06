# Migration from interaction-design-decision-coach

## 名前

| 旧 | 新 |
|---|---|
| `interaction-design-decision-coach` | `interaction-design-review-agent` |

## 概念の対応

| 旧構造 | 新構造 |
|---|---|
| project | project |
| actors | actors |
| constraints | constraints |
| principles | principles |
| decisions | decisions |
| states / transitions | state_machine |
| contradictions | contradictions |
| assumptions | assumptions |
| なし | pipeline |
| なし | facts |
| なし | business_workflow |
| なし | business_understanding |
| なし | decision_requirements |
| なし | target_value_loop |
| なし | decision_table（必要な場合だけ） |
| なし | information_architecture |
| なし | ui_behaviors |
| なし | questions |
| なし | traceability |

## 自動変換

```bash
python3 scripts/migrate_v0_1_state.py old-state.json new-design-case.json
```

変換後は次を実行する。

```bash
python3 scripts/validate_design_case.py new-design-case.json
python3 scripts/review_pipeline.py new-design-case.json
```

旧データに存在しなかった項目は空で作成されるため、Business Understandingから順番に補完する。Decision Tableは複数条件の組合せがある判断だけ作成する。
