---
name: claude-fable-review
description: Use only when the user explicitly asks for Fable/Claude review. Runs a simple claude -p call with the Fable model at high effort, blocking only edit tools, and handles resume for re-review.
---

# Claude Fable Review

## Trigger Rule

- Use this skill only when the user explicitly asks for Fable review, Claude review, or to consult Fable.
- Do not auto-trigger this skill for generic "review", planning, or post-commit review requests.
- Default review path remains `codex-exec-review` unless the user explicitly selects Fable.

## When Invoked

- Before presenting an implementation plan to the user, run `claude -p` with Fable to review the plan if the user explicitly asked for Fable review.
- After a non-trivial commit, run `claude -p` with Fable to review the committed change if the user explicitly asked for Fable review.
- Repeat review up to 3 times. Stop when no critical issue remains.
- Do not replace a requested Fable review with local tests or your own judgment.

## Review Command Rules

- Use `env claude -p` to avoid shell aliases such as `claude --dangerously-skip-permissions`.
- Pass `--model global.anthropic.claude-fable-5` explicitly. Do not rely on the root `"model"` setting (it defaults to sonnet).
- Pass `--effort high` explicitly. Do not leave effort at the CLI default.
- Pass `--disallowedTools "Edit,Write,NotebookEdit"` so the reviewer cannot modify files. Everything else (normal settings, CLAUDE.md, skills, MCP, permissions) loads as usual.
- Do not use `--safe-mode`, `--bare`, custom `--settings` JSON, or `--tools`/`--allowedTools` lists. The normal `claude/settings.json` permissions (including its deny rules) apply.
- In the prompt, separate depth from output: investigate thoroughly, but report only critical issues.
- Instruct the reviewer not to run tests, build, format, install, generation, mutation, or deployment commands, and not to start another `claude -p`, `codex exec`, or `mcp__ais` call.
- Instruct the reviewer not to paste private code, secrets, env values, customer data, or large local diffs into web queries.
- Pass intent alongside the artifact: give `PLAN_OR_DIFF_REF` plus 3-5 lines of change intent, acceptance criteria, and known concerns. Fable performs better when it knows why the change exists.

## Initial Review Template

Set `PLAN_OR_DIFF_REF` to the full path, commit ref, or concise description being reviewed. Set `REVIEW_INTENT` to 3-5 lines of intent / acceptance criteria / known concerns.

```bash
set -o pipefail

REVIEW_LOG=${REVIEW_LOG:-review-result.jsonl}

env claude -p \
  --model global.anthropic.claude-fable-5 \
  --effort "${CLAUDE_REVIEW_EFFORT:-high}" \
  --disallowedTools "Edit,Write,NotebookEdit" \
  --output-format json \
  "このプランまたは差分をレビューして。調査・検証は徹底的に行い、報告は致命的な点だけに絞って。テスト・build・format・install・生成・編集・mutation・deploy コマンドは実行せず、差分・設定・既存ログの読取を主材料に判断して。現行仕様確認には WebSearch/WebFetch を使ってよいが、private code・secret・env 値・customer data・大きな local diff を検索クエリや取得 URL に貼らないで。別の claude -p、codex exec、mcp__ais、外部レビューコマンドは絶対に起動しないで。回答内容が現時点で out of date / deprecated になっていないかにも気をつけて。Web を使った場合は参照 URL と判断への使い方を短く添えて。

変更の意図・背景: $REVIEW_INTENT

レビュー対象: $PLAN_OR_DIFF_REF" \
  | tee "$REVIEW_LOG"
```

Capture the session id from the result JSON:

```bash
jq -r '.session_id' "$REVIEW_LOG" | tail -n 1
```

## Resume Review Template

Use the same session for updated plan reviews:

```bash
set -o pipefail

REVIEW_LOG=${REVIEW_LOG:-review-result.jsonl}

env claude -p \
  --model global.anthropic.claude-fable-5 \
  --effort "${CLAUDE_REVIEW_EFFORT:-high}" \
  --disallowedTools "Edit,Write,NotebookEdit" \
  --output-format json \
  --resume "$SESSION_ID" \
  "前回の指摘を反映してプランまたは差分を更新した。もう一度レビューして。前回と同じ制約で、調査は徹底、報告は致命的な点だけ。新しく追加された問題がなければ、その旨を明示して: $PLAN_OR_DIFF_REF" \
  | tee "$REVIEW_LOG"
```

For progress visibility on long reviews, `--output-format stream-json --include-partial-messages --verbose` may be used instead; the final `type == "result"` event carries `.session_id`.

## Safety Caveats

- This mode is intentionally lighter than the old `--safe-mode` + settings-injection setup. Edit/Write/NotebookEdit are hard-blocked; everything else is governed by the normal `claude/settings.json` permissions (its deny list already blocks `sudo`, `rm -rf`, `git reset`, force push) plus prompt constraints.
- Destructive Bash beyond the settings deny list (e.g. `git checkout`, `mv`) is not hard-blocked. Run reviews from a clean worktree, or add specific `Bash(...)` patterns to `--disallowedTools` if a repo warrants it.
- If the reviewer needs command output that it should not produce itself (test runs, builds), provide existing logs or run the command yourself outside the review.

## Timeout Semantics

- Wait for the final result JSON before reporting success:
  - about 15s for trivial prompts
  - about 30-60s for light reviews
  - about 180s for normal review tasks; high effort may take longer
- `review started but final result not yet returned` is not `review complete`.
- For a required review, if the final answer is missing, try at least one `--resume "$SESSION_ID"` or rerun.
- If the final answer still cannot be recovered, report `review incomplete` and ask the user how to proceed.
- Do not say a review passed unless the final review answer was obtained.

## Validation

- Verified with Claude Code 2.1.220: `claude -p --model global.anthropic.claude-fable-5 --effort high --disallowedTools "Edit,Write,NotebookEdit" --output-format json` returns a result JSON with `.session_id` and `modelUsage."global.anthropic.claude-fable-5"`.
- `MAX_THINKING_TOKENS` was removed from `dotfiles/claude/settings.json` (2026-08-16); it capped Fable's extended thinking at 1024 tokens for both interactive and `-p` use.
- After editing this skill, run:

```bash
python3 /Users/lilpacy/dotfiles/codex/skills/.system/skill-creator/scripts/quick_validate.py /Users/lilpacy/dotfiles/skills/claude-fable-review
```
