# /ir-pipeline — Text ↔ IR ↔ Text with Lint

## Usage
Run this command and provide an input block.

### Input block (recommended)
```yaml
mode: from-text   # from-text | from-ir | lint-only | to-text
type: paper       # paper | tech | doc (omit to auto-detect)
target: blog      # paper: paper|blog|memo / tech: howto|rfc|adr|postmortem|blog / doc: chronological|mystery_reveal|thesis_then_evidence
language: ja      # ja|en
length: short     # short|medium|long
input:
  inline: |
    (paste text or IR yaml here)
# or:
# input:
#   path: path/to/file.md
```

## What this command does
1) Detects input kind (text vs IR) and document type (paper/tech/doc)
2) Converts to IR if needed (paper_text2ir / tech_text2ir / doc_text2ir)
3) Runs lint (ir_lint_validator + optional tools/ir_lint.py)
4) Auto-fixes FAILs up to 2 iterations (minimal diffs only)
5) Generates output text if requested (paper_ir2text / tech_ir2text / doc_ir2text)
6) Saves artifacts under `artifacts/ir_pipeline/`

## Execute
Call the subagent: `@ir_pipeline_coordinator` with the input block above.
