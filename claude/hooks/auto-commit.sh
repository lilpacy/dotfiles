#!/bin/bash
# Auto-commit hook for Claude Code Stop event
# Uses codex exec --yolo to split and commit changes directly

INPUT=$(cat /dev/stdin)
CWD=$(echo "$INPUT" | jq -r '.cwd')

cd "$CWD" || exit 0

# Only proceed in git repos
git rev-parse --git-dir > /dev/null 2>&1 || exit 0

# Only proceed if there are changes
if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
  exit 0
fi

codex exec \
  --yolo \
  --model gpt-5.3-codex-spark \
  "Look at the current git diff and untracked files. Group related changes into logical commits and commit them.

Rules:
- Group related changes together (same feature, same config area)
- If all changes are related, make a single commit
- Do NOT split trivially — only split if changes are clearly independent
- Use conventional commits style (max 72 chars)
- Stage and commit directly using git add and git commit" 2>/dev/null || true

exit 0
