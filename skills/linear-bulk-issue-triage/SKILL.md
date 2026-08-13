---
name: linear-bulk-issue-triage
description: Guide Q&A-driven bulk Linear issue creation from a raw task list. Use when the user wants to split many task lines into Linear issues, choose workspace/team/title/description/due dates, skip completed items, or create issues only after explicit per-item confirmation while minimizing decision load.
---

# Linear Bulk Issue Triage

## Overview

Turn a raw task list into Linear issues through a low-friction interview loop. Ask exactly one confirmation question at a time, create only confirmed issues, and preserve the user's corrections as the source of truth.

## Core Rule

Never batch confirmation questions. For every candidate issue, ask one focused question, wait for the answer, then create, skip, or revise that one item before moving on.

## Workflow

1. Inspect the current Linear context before creating anything:
   - Run `linear auth list`.
   - Run `linear -w <workspace> team list` for the target workspace when team keys are not already certain.
   - Use explicit `-w <workspace>` in every mutating command.
2. Normalize the raw list into ordered candidate issues:
   - Preserve original order.
   - Treat indented lines as possible details or possible same-issue continuations, but do not merge them without confirmation.
   - Detect obvious duplicates, but still ask before merging or skipping.
3. Ask one question for the next candidate:
   - Include proposed `team`, `title`, optional `due date`, and `description`.
   - Keep the question short enough that the user can answer with `y`, a correction, or `起票しない`.
4. Interpret the answer:
   - `y`, `yes`, `ok`: create the proposed issue.
   - `y 期限は8/3`: create with the accepted proposal plus the amended due date.
   - `teamはANI`, `descを...`: apply the correction, create only if the answer also confirms creation; otherwise ask the revised one-question confirmation.
   - `起票しない`, `終わってる`, `これは起票しない`: skip the candidate and move to the next one.
   - If the user gives exact `team`, `title`, and `due date` and says to create, treat that instruction as confirmation for those specified issues.
5. Create the issue with Linear CLI:
   - Use `linear -w <workspace> issue create --team <TEAM> -t '<title>' ... --no-interactive`.
   - Add `--due-date YYYY-MM-DD` when a due date is confirmed.
   - Prefer `--description-file` for multiline Markdown. Inline `-d` is acceptable for simple one-line descriptions.
6. After each successful creation:
   - Report the created issue key, team, title, and due date if present.
   - Ask the next single confirmation question.
7. If Linear returns a transient error such as `503`, state that the issue was not created, retry once, and only continue after success or clear failure.

## Date Handling

Convert informal dates to concrete ISO dates before creating issues.

| User date | Action |
|---|---|
| `8/3` and the date is upcoming this year | Use `YYYY-08-03` for the current year |
| `7/31` and the date is upcoming this year | Use `YYYY-07-31` for the current year |
| Date already passed this year | Ask one question to confirm the intended year |
| `10日まで` | Ask if the month is ambiguous unless context clearly establishes it |

## Proposal Shape

Use a compact table when proposing an issue:

```markdown
次の1件です。

`元のタスク行` は `<TEAM>` に起票してよいですか？

| 項目 | 案 |
|---|---|
| team | `<TEAM>` |
| title | `<title>` |
| due date | `<YYYY-MM-DD>` |
| description | `<description>` |
```

Omit rows that are not relevant, such as `due date` when none is proposed.

## Team Assignment

Use the user's stated team rules first. When rules are not stated, ask one question to establish the default mapping before triaging individual items.

Example mapping from this workflow:

| Team | Use for |
|---|---|
| `LIL` | Personal work, life admin, investing, Codex/skills/Obsidian/ChatGPT tooling |
| `ANI` | Aniark work, production management, Zach/LIDEN/LucidLink/recruiting/PR/company tasks |

User corrections override the mapping for the current item and should inform later similar items.

## Creation Command Examples

Simple one-line issue:

```bash
linear -w lilpacys-workspace issue create --team ANI -t 'Zachとのミーティングを設定する' -d 'Zachとのミーティング候補日を調整し、予定を確定してカレンダー等に登録する。' --no-interactive
```

Issue with due date:

```bash
linear -w lilpacys-workspace issue create --team LIL -t '家賃の引き落とし登録を行う' -d '家賃の引き落とし登録に必要な情報を確認し、手続きを完了する。' --due-date 2026-07-31 --no-interactive
```

Multiline Markdown description:

```bash
linear -w lilpacys-workspace issue create --team LIL -t 'タスク管理をLinearに移行する' --description-file /path/to/description.md --no-interactive
```

## Final Summary

When the original list is exhausted, report a brief count by team and state that skipped/completed items were not created. Do not dump every issue unless the user asks.

If the user wants to classify the created issues into projects or milestones, estimate near-term work, or plan cycles, hand off to `linear-work-planning` instead of extending this creation loop.
