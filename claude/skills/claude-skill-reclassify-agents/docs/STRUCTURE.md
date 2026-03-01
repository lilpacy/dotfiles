# Supported repo structures (examples)

## Subagents
Common:
- `.claude/agents/<name>.md`

Also supported:
- `.claude/subagents/<name>.md`
- `agents/<name>.md`
- `subagents/<name>.md`

## Skills
Folder-based:
- `.claude/skills/<skill-name>/SKILL.md`

Loose markdown skills (scanned as well):
- `.claude/skills/<something>.md`
- `skills/<something>.md`

You can override all paths in `config.yaml`.
