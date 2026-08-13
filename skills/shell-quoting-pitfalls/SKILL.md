---
name: shell-quoting-pitfalls
description: Use when composing shell commands whose arguments contain markdown backticks (PR bodies, commit messages, rg/grep patterns), when writing zsh for-loops or scripts, or when debugging errors like "command not found" after a loop, corrupted PR descriptions, or search patterns that executed commands. Covers command substitution via backticks, zsh special variables, and safe stdin/file-based argument passing.
---

# Shell Quoting Pitfalls

## Overview

Backticks inside double quotes are still command substitution, and zsh ties
some lowercase variable names to the environment. Both failure modes have
corrupted real PR bodies and broken `$PATH` mid-session. Pass rich text via
stdin or files, never as inline double-quoted arguments.

## Pitfall Table

| Symptom | Cause | Fix |
|---|---|---|
| PR/issue body contains command output instead of `` `code` `` | Backticks in `gh pr create --body "..."` executed as command substitution. JSON-stringifying the body does NOT prevent this | Write body with a quoted heredoc (`<<'EOF'`) to a file, then `--body-file`; or `gh api --input -` with JSON on stdin |
| `zsh: command not found: curl/sed/...` after a for-loop | `for path in ...` overwrote zsh's special `$path` array, which is tied to `$PATH` | Never use `path` (also avoid `cdpath`, `fpath`, `manpath`, `status`) as a loop/local variable in zsh. Use `url_path`, `p`, etc. |
| `command not found: —` or garbage while running `rg`/`grep` | Backticks inside a double-quoted search pattern executed as commands | Single-quote patterns containing backticks, or drop the backticks from the search term |

## Rules

1. Multi-line or markdown-containing text (PR body, commit message, issue
   comment) goes through a file or stdin, written with a **quoted** heredoc
   delimiter (`cat <<'EOF' > file`). An unquoted `<<EOF` still expands
   backticks and `$vars`.
2. After creating/updating a PR this way, verify with
   `gh pr view --json title,body`.
3. In zsh one-liners, treat `path`, `fpath`, `cdpath`, `manpath`, `status`
   as reserved.
4. Search patterns are single-quoted by default; switch to double quotes
   only when you intentionally need expansion.

## Example

```sh
cat <<'EOF' > /tmp/pr-body.md
## Summary
Fixed retry logic in `lib/retry.ts`. Verified with `pnpm test retry`.
EOF
gh pr create --title "fix: correct retry logic" --body-file /tmp/pr-body.md
gh pr view --json title,body
```

## Real-World Impact

Three independent incidents in this environment: a PR description destroyed
by executed backticks (github:lilpacy/obsidian#75), a diagnostics loop that
lost `curl`/`sed`/`npx` after `for path in ...` under zsh, and an `rg`
pattern whose backticks ran as commands during a docs audit.
