# Skill: Reclassify existing subagents vs skills and migrate

## Intent
Scan an existing repo for *Claude Code subagents* and *skills*, decide which each item should be, and **apply the conversion** by moving/rewrapping files into the appropriate structure — with backups and a migration report.

This skill is designed for repos that contain:
- subagents as Markdown files (commonly `.claude/agents/*.md`)
- skills as either:
  - folder-based skills (`.claude/skills/<skill>/SKILL.md`), or
  - single Markdown skills (various conventions)

If your structure differs, adjust `config.yaml`.

---

## Inputs you need from the user (or derive automatically)
- repository root (assume current working directory is repo root)
- optional: path to config (`config.yaml`)
- desired mode:
  - `dry-run` (generate report only)
  - `apply` (convert + update references)

---

## Outputs
- `reclassify-report.md`
  - list of items
  - current type (agent/skill/unknown)
  - recommended type
  - confidence score
  - top rationale signals
  - migration plan summary
- backups under `.reclassify_backup/<timestamp>/...`
- migrated files in:
  - `target_agents_dir` (default `.claude/agents`)
  - `target_skills_dir` (default `.claude/skills/<name>/SKILL.md`)

---

## Operating rules (guardrails)
1. Always create a backup snapshot under `.reclassify_backup/...` before writing.
2. Prefer running on a git branch (create one if possible).
3. Never delete originals; if moving, keep an embedded appendix OR keep an original copy under backup.
4. If an item references tools/paths that do not exist, preserve the text; do not “fix” behavior beyond migration.
5. Update references best-effort (rename mentions), but do not break code; keep replacements conservative.

---

## Procedure (high-level)
1) **Discover** existing agents & skills by scanning configured directories (and auto-detect when missing).
2) **Classify** each item using the rubric:
   - Skill score ↑ with procedural/template/checklist/format markers
   - Subagent score ↑ with role/principles/judgment/exploration markers
3) **Report**: write `reclassify-report.md` with confidence & rationale.
4) **Convert**:
   - Agent → Skill:
     - create folder `target_skills_dir/<name>/SKILL.md`
     - rewrap content into a Skill template (Goal / Inputs / Outputs / Procedure / Guardrails)
   - Skill → Agent:
     - create `target_agents_dir/<name>.md`
     - rewrap content into an Agent template (Role / Principles / How to respond)
5) **Reference updates** (optional):
   - search Markdown files and replace references to moved paths/names where safe.
6) **Summary**: print a small summary and point to report + backup path.

---

## How to run (recommended)
Use the provided script to execute the procedure end-to-end:

```bash
python3 .claude/skills/reclassify-agents/scripts/reclassify.py --config .claude/skills/reclassify-agents/config.yaml --mode dry-run
python3 .claude/skills/reclassify-agents/scripts/reclassify.py --config .claude/skills/reclassify-agents/config.yaml --mode apply
```
