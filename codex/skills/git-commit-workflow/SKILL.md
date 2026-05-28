---
name: git-commit-workflow
description: Use when committing, pushing, or preparing PRs. Defines the user's commit workflow, message style discovery, review handoff, and branch/worktree push requirements.
---

# Git Commit Workflow

## Before Commit

- Inspect `git status --short`.
- Do not revert user changes unless explicitly requested.
- Commit only coherent, orthogonal units.
- Check recent commit message style before writing the commit message:

```bash
git log --oneline -5
```

## After Implementation

- Run the relevant tests or checks for the change.
- If tests cannot be run, say exactly why.
- Commit after implementation and verification.

## After Commit

- For non-trivial changes, use `codex-exec-review` after committing.
- If review reports critical issues, fix them, test again, commit or amend only when appropriate, and rerun review.
- Do not treat `review incomplete` as approval.

## Push And PR

- If the work is on a separate branch or worktree, push the branch and open a GitHub PR.
- Do not push unrelated local work.
