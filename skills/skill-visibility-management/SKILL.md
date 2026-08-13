---
name: skill-visibility-management
description: Use when changing which skills Claude or Codex can see — requests like "make X visible from codex", "codexからも使えるように", "このskillをclaudeに追加", hide/remove a skill from an agent, list per-agent skills, or check symlink drift. Also use immediately after creating a new skill in dotfiles/skills/, and whenever tempted to run ln -s directly into claude/skills/ or codex/skills/.
---

# Skill Visibility Management

## Overview

Per-agent skill visibility is declared in one place:
`~/dotfiles/link-skills.sh` (`CLAUDE_SKILLS` / `CODEX_SKILLS` arrays).
Symlinks under `claude/skills/` and `codex/skills/` are generated output,
never hand-edited. A hand-made `ln -s` works today and silently disappears
on the next machine, because `link.sh` only reproduces what the arrays
declare.

**Editing the array IS the operation. The symlink is a build artifact.**

## Operations

| Request | Action |
|---|---|
| Show skill X to an agent | Add `X` to that agent's array (keep alphabetical order), run `./link-skills.sh` |
| Hide skill X from an agent | Remove `X` from the array, delete the symlink (`/usr/bin/trash claude/skills/X`), run `--audit` |
| New skill created in `skills/` | Decide per agent, add to arrays, run `./link-skills.sh` |
| List visibility | Read the two arrays — they are the answer. Don't `ls` the symlink dirs |
| Check drift | `./link-skills.sh --audit` (exit 1 + report on any mismatch) |

## Required Sequence

```bash
# 1. Edit the arrays in link-skills.sh (the ONLY mutation step)
# 2. Regenerate
~/dotfiles/link-skills.sh
# 3. Verify zero drift
~/dotfiles/link-skills.sh --audit
# 4. Commit link-skills.sh together with the symlink changes
```

Commit the array edit and the symlink in the same commit; a symlink commit
without the matching array edit recreates the drift this skill exists to
prevent.

## Rationalization Table

| Excuse | Reality |
|---|---|
| "It's just one symlink, ln -s is faster" | The link vanishes on the next `link.sh` bootstrap. This exact shortcut created 17 undeclared symlinks. |
| "I'll update the list later" | Later never came — audit found 4 same-day violations by the agent that knew the script existed. |
| "The symlink already exists, so it's visible" | Visible on this machine only. Undeclared = unreproducible. |
| "ls the directory to answer 'which skills'" | Directories show drifted state; the arrays show intent. Report both only when auditing. |

## Red Flags — STOP

- About to type `ln -s` with a target under `claude/skills/` or `codex/skills/`
- Committing a new symlink without a `link-skills.sh` diff in the same commit
- `--audit` exits 1 and you proceed anyway

Any of these: go back to the Required Sequence, step 1.

## Notes

- A real (non-symlink) directory inside an agent dir is either an
  agent-specific skill (leave it) or an accidental copy — diff against
  `skills/<name>` before touching it; replace with a symlink only when
  identical, using `/usr/bin/trash`, never `rm -rf`.
- `~/.agents/skills` points at `dotfiles/skills/` directly (all skills);
  the per-agent dirs are curated subsets. Codex reads both.
