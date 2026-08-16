---
name: skill-visibility-management
description: Use when listing or changing which skills Claude Code or Codex can see, enabling or disabling a skill for either agent, promoting an agent-specific skill into the canonical dotfiles/skills store, or checking visibility drift. Also use after creating a canonical skill when the user wants to expose it to an agent.
---

# Skill Visibility Management

Use `~/dotfiles/bin/skill-visibility` as the only interface. Do not edit
`link-skills.sh`, `claude/skills`, or `codex/skills` directly.

## Start With the Matrix

For inventory, organization, or mutation requests, first run:

```bash
skill-visibility list
```

The matrix distinguishes:

- `CANONICAL=yes`: a source exists in `~/dotfiles/skills`.
- `canonical-link`: the agent sees the canonical source through its curated link.
- `off`: the agent does not see it through its curated directory.
- `agent-specific`: only that agent has a real directory.
- `agent-specific-divergent`: a real agent copy differs from the same-named canonical source.

## Operations

```bash
skill-visibility enable claude <skill>
skill-visibility enable codex <skill>
skill-visibility disable claude <skill>
skill-visibility disable codex <skill>
skill-visibility promote claude <skill>
skill-visibility promote codex <skill>
skill-visibility audit
```

`enable` and `disable` update the declaration, regenerate links, audit, and roll
back on failure. Report the resulting state to the user.

An agent-specific real directory cannot be deleted by `disable`. To turn it off
without losing it, run `promote <agent> <skill>` and then `disable <agent>
<skill>`. This preserves the content in the canonical store.

## Promotion Conflicts

When both agents have the same agent-specific Skill:

- Identical contents are consolidated into one canonical source and both agents
  keep visibility.
- Different contents stop before mutation. Show the conflict and ask which
  agent's copy should become canonical.
- After the user explicitly chooses the source, run that source with
  `--keep-divergent`; the unselected copy remains agent-specific-divergent.

```bash
skill-visibility promote codex <skill> --keep-divergent
```

Do not infer a winner from timestamps or names.

## Discovery Checks

Normal completion uses `skill-visibility audit`; do not launch extra model
sessions after every change. Start a fresh Claude Code or Codex session only
after changing a discovery root, or when the matrix and the agent's observed
skills disagree.
