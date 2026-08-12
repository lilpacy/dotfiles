---
name: codex-thread-branch-diagnostics
description: Diagnose Codex TUI failures that say a selected prompt was not found in the persisted thread, using read-only checks across rollout JSONL, SQLite projections, and Codex doctor output.
---

# Codex Thread Branch Diagnostics

Diagnose prompt-level branch/edit failures without deleting or rebuilding user history.

## Safety

- Keep every diagnostic read-only.
- Never print or inspect `auth.json` contents.
- Do not delete SQLite databases, WAL files, rollout JSONL, or lock files as a speculative fix.
- Do not reproduce by branching the live thread unless the user asked for a state-changing test.

## Workflow

1. Read current official Codex app-server documentation for `thread/fork`. Confirm that a branch copies stored history and that `lastTurnId` bounds the copied turns.
2. Record `codex --version`, then run `codex doctor --json`. Check `state.paths`, `state.rollout_db_parity`, and `updates.status` before blaming corruption or an old version.
3. Identify the likely source thread from `~/.codex/state_5.sqlite` using read-only queries ordered by `updated_at_ms`. Label a time-based identification as inferred.
4. In its rollout JSONL, extract only genuine user prompts:
   - `response_item` where payload is a user `message`;
   - `event_msg` where the completed item is `UserMessage`.
   Compare timestamps, turn IDs, item IDs, and normalized text.
5. In `~/.codex/thread_history_1.sqlite`, compare `thread_turns` and `thread_items` for the same thread. Verify the selected prompt exists as `item_type = 'userMessage'`, its turn is complete, and `first_user_item_id` matches the projected item.
6. Classify the result:
   - missing from JSONL: persisted rollout does not contain that prompt;
   - present in JSONL but absent from the projection: projection/index inconsistency;
   - present in both with a completed turn: likely TUI selection-to-persisted-item mapping failure, not history loss;
   - selected item is a steer or belongs to an active turn: unsupported branch boundary.
7. Offer the smallest workaround. Restart and `codex resume <SESSION_ID>` first. Use `codex fork <SESSION_ID>` only when a full-thread fork is acceptable; it does not select an earlier turn. For an exact cutoff, the app-server API supports `thread/fork` with `lastTurnId`, but do not mutate state without user authorization.

## Reporting

State what is confirmed, what is inferred, and whether history loss was ruled out. Include the Codex version, doctor integrity/parity result, and the minimal workaround. Avoid dumping prompt text unless needed.
