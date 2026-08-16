---
name: skill-visibility-management
description: Use when listing or changing which skills Claude Code or Codex can see, opening the interactive Skill visibility TUI, enabling or disabling a skill for either agent, promoting an agent-specific skill into the canonical dotfiles/skills store, or checking visibility drift. Also use after creating a canonical skill when the user wants to expose it to an agent.
---

# Skill Visibility Management

Use `~/dotfiles/bin/skill-visibility` as the only interface. Do not edit
`link-skills.sh`, `claude/skills`, or `codex/skills` directly.

## Choose the Entry Point

- For broad inventory or organization, use `skill-visibility tui`. It keeps the
  full matrix visible and supports search, direct operations, and optional
  background planning by Codex or Claude.
- For an explicitly named Skill, agent, and action, first inspect the current
  row with `skill-visibility list`, then run the matching CLI operation.
- If the user asks for the inventory in conversation, show the matrix before
  recommending or changing anything. Wait for the user's selection unless the
  request already contains an explicit Skill, agent, and action.

Never choose a Skill, agent, promotion source, or mutation on the user's behalf.

## TUI

```bash
skill-visibility tui
skill-visibility tui --agent claude
```

The TUI sends deterministic list, search, enable, disable, promote, and audit
operations directly through the existing CLI logic. `:` sends only an
ambiguous natural-language request to a background read-only Agent. The Agent
returns a plan; it cannot apply changes. The user must approve the plan, and
the approved operations then use the same validation, rollback, audit, and
result contract as direct TUI operations.

The lower pane shows the selected Skill's frontmatter `description`. Press `o`
only when the full Skill folder needs inspection.

## CLI Operations

```bash
skill-visibility list
skill-visibility list --json
skill-visibility enable claude <skill>
skill-visibility enable codex <skill>
skill-visibility disable claude <skill>
skill-visibility disable codex <skill>
skill-visibility promote claude <skill>
skill-visibility promote codex <skill>
skill-visibility audit
```

`enable`, `disable`, and `promote` update declarations, regenerate links, audit,
and preserve the pre-operation state on failure. Report the resulting state.

An agent-specific real directory cannot be deleted by `disable`. To turn it off
without losing it, run `promote <agent> <skill>` and then `disable <agent>
<skill>`.

## Promotion Conflicts

- Identical agent-specific copies consolidate into one canonical source while
  preserving both agents' visibility.
- Different contents stop before mutation. Show the differing files and ask
  which agent's copy becomes canonical.
- Only after the user chooses, run the selected source with
  `--keep-divergent`; keep the unselected copy agent-specific-divergent.

Do not infer a winner from timestamps or names.

## Discovery Checks

Normal completion uses the local audit. Start a fresh Claude Code or Codex
session only after changing a discovery root, or when the matrix and observed
skills disagree.
