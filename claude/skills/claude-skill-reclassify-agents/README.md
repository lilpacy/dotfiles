# Reclassify Agents vs Skills (Claude Code Skill)

This package provides a **Claude Code skill** that:
1) scans your repo for existing **subagents** and **skills**,
2) recommends whether each should be a **subagent** or a **skill**,
3) generates a migration report, and
4) can **apply the conversion** (with backups + git-friendly changes).

## Quick start

### 1) Copy into your repo
Place the folder contents into your repo (recommended location):
- `.claude/skills/reclassify-agents/`  *(or any skills folder you use)*

### 2) Configure (optional)
If your repo does not use the default paths, copy and edit:

- `config.example.yaml` → `config.yaml`

### 3) Run (two-phase recommended)
Dry run (report only):
```bash
python3 .claude/skills/reclassify-agents/scripts/reclassify.py --config .claude/skills/reclassify-agents/config.yaml --mode dry-run
```

Apply changes (writes/moves files + updates references + backups):
```bash
python3 .claude/skills/reclassify-agents/scripts/reclassify.py --config .claude/skills/reclassify-agents/config.yaml --mode apply
```

## What gets produced
- `reclassify-report.md` — recommendation + rationale per item
- `.reclassify_backup/<timestamp>/...` — full backup of touched files
- migrated/rewrapped skills & agents per the mapping

## Safety
- Never deletes originals (backs up first)
- Designed to be run on a git branch

Generated: 2026-03-01 (UTC)
