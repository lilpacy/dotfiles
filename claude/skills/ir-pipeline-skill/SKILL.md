# IR Pipeline Skill (PaperIR / TechIR / DocumentaryIR)

このスキルは、以下のパイプラインを **同一手順・最小コンテキスト**で回すための “Coordinator + Subagents + Lint” パッケージです。

- 文章 → IR（PaperIR / TechIR / DocumentaryIR）
- IR → Lint（直交性・非重複性（SoT）・適粒度+高凝集・anchors・参照整合性）
- 必要なら IR → 文章（UI向けの読み替え）

## Contents
- `.claude/agents/`:
  - `ir_pipeline_coordinator.md`（司令塔）
  - `paper_text2ir.md`, `paper_ir2text.md`
  - `tech_text2ir.md`, `tech_ir2text.md`
  - `doc_text2ir.md`, `doc_ir2text.md`
  - `ir_lint_validator.md`（lint subagent）
- `.claude/commands/ir-pipeline.md`（/ir-pipeline コマンド）
- `scripts/ir_lint.py`（ローカル機械lint。PyYAMLがあればYAML対応）

## Install
以下をグローバルにコピー：

- `.claude/agents/` → `~/.claude/agents/`
- `.claude/commands/` → `~/.claude/commands/`
- `scripts/ir_lint.py` はskill配下 (`~/.claude/skills/ir-pipeline-skill/scripts/`) に同梱済み

## Run
Claude Codeで `/ir-pipeline` を実行し、YAML入力ブロックを貼るだけです。

### Example: 技術記事 → IR → lint → RFC生成
```yaml
mode: from-text
type: tech
target: rfc
language: ja
length: medium
input:
  path: docs/design.md
```

### Example: 既存IRのlintだけ
```yaml
mode: lint-only
input:
  path: artifacts/ir_pipeline/ir.yaml
```

## Notes
- 生成は **anchors** と **ID参照** を最優先し、IRにない事実を追加しません。
- FAILの自動修正は **最大2回**。それ以上は入力（出典/本文）不足の可能性が高いです。
