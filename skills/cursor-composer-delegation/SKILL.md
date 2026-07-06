---
name: cursor-composer-delegation
description: "Delegate coding tasks to Cursor IDE's Composer agent via the macOS Accessibility API (cursor-compose) while acting as PM: write specs, dispatch prompts, then verify results from the working tree."
---

# Cursor Composer Delegation

Act as the PM: plan and review in this session (works from any PM agent
-- Codex, Claude Code, etc.), and delegate the actual code editing to
Cursor's Composer agent (Composer model) running in the Cursor IDE.
Dispatch is done with the `cursor-compose` CLI, which writes directly
into the Composer textarea via the macOS Accessibility API — it does
NOT steal focus, send global keystrokes, or touch the clipboard, so the
user can keep working in other apps while prompts are dispatched.

## Prerequisites

- `Cursor.app` is running with the Composer pane open.
- `cursor-compose` is on PATH (`~/dotfiles/bin/cursor-compose`), with
  its compiled helper `cursor-compose-ax` next to it. Rebuild after
  editing the source:
  `swiftc -O ~/dotfiles/bin/src/cursor-compose.swift -o ~/dotfiles/bin/cursor-compose-ax`
- `cursor-compose-status` is on PATH (`~/dotfiles/bin/cursor-compose-status`),
  a compiled Swift helper that reports whether Composer is generating.
  Rebuild after editing the source:
  `swiftc -O ~/dotfiles/bin/src/cursor-compose-status.swift -o ~/dotfiles/bin/cursor-compose-status`
- The terminal running this session has Accessibility permission
  (System Settings > Privacy & Security > Accessibility).
- Cursor's Composer is set to the desired model (e.g. Composer) and
  auto-run is enabled if you want unattended edits.

## Workflow

1. Open the target repo in Cursor once per task:

   ```bash
   cursor-compose --dir /path/to/repo --new "<task prompt>"
   ```

   `--dir` opens the directory in Cursor first; `--new` starts a fresh
   Composer chat so context from prior tasks does not leak.

2. Write the prompt like a work order, not a conversation:
   - Goal, constraints, acceptance criteria.
   - Exact file paths when known.
   - "Do not commit" — commits are the PM's job.

3. Wait for Composer to finish, then verify from the filesystem.
   Cursor edits the working tree directly. Instead of blind
   fixed-interval `sleep`, block on the generation state:

   ```bash
   cursor-compose-status              # prints "busy" (exit 0) or "idle" (exit 1)
   cursor-compose-status --wait 1200  # poll every 5s until idle (or timeout seconds)
   ```

   `--wait` detects generation by finding Composer's inline "Stop
   generation" AXButton; it requires 2 consecutive idle reads so a
   brief gap between tool-calls is not mistaken for completion.

   CRITICAL: dispatch is asynchronous — `cursor-compose` returns before
   Composer starts generating. Calling `cursor-compose-status --wait`
   too fast can observe the pre-generation idle state and return
   instantly with zero diff. After dispatching, either `sleep 30-45`
   first, or confirm `cursor-compose-status` prints `busy` before you
   `--wait`. Once idle, verify with:

   ```bash
   git -C /path/to/repo status --porcelain
   git -C /path/to/repo diff
   ```

   Run the project's tests/linters yourself to accept or reject the work.
   If no diff appeared, the prompt may have queued behind a still-running
   task (see Notes on queuing) or landed in the wrong Cursor window.

4. If the result is wrong, send a follow-up in the same chat
   (omit `--new`):

   ```bash
   cursor-compose "The test X still fails with Y. Fix it without touching Z."
   ```

5. When accepted, commit via the normal `git-commit-workflow` skill.

## Branch / Worktree Control

Control the editor state from the shell — never via UI automation:

- Branch switch: run `git switch <branch>` in the repo. Cursor follows
  the working tree automatically (file watcher); no IDE interaction
  needed and no focus is taken.
- Worktree / another repo: `cursor-compose --dir <path>` (wraps
  `cursor <path>`). An already-open worktree reuses its window.
- NEVER switch branches while Composer is mid-task in that window —
  it will write into the post-switch tree. Switch only after the diff
  has been verified. For parallel tasks, use one Cursor window per
  worktree.
- If the user is working in the same repo, coordinate: the PM should
  take a worktree instead of switching the user's checkout.

## Notes

- Dispatch is focus-free: AXValue is set on the Composer textarea and
  the "Send message" button is pressed via AXPress, scoped to the
  Cursor process. No clipboard use, no focus stealing.
- Because text goes through AXValue (not typed keystrokes), prompts are
  delivered verbatim: multi-KB prompts, Japanese, quotes, backticks,
  `$vars`, and literal `\n` are all safe. No shell-escaping gymnastics
  needed beyond normal quoting of the argument.
- Sending while Composer is still working queues the message in the
  same chat; Composer processes them in order. This works, but the PM
  loses per-task verification — prefer dispatch → verify diff → next
  dispatch. Follow-ups in one chat retain prior context (Round-trip
  fix loops like "tests fail with X, fix it" work well).
- If dispatch fails with "textarea not found", the Composer pane is
  closed in Cursor — ask the user to open it (cmd+i) once.
- Dispatch targets the first Composer textarea found in the Cursor
  process. With multiple Cursor windows open, the prompt may land in
  another window's Composer — always confirm via the diff in the
  expected repo, and treat "no diff appears" as a possible wrong-window
  dispatch.
- `cursor-compose-status` matches the exact AXButton description
  `Stop generation` (Cursor's inline stop control). If a Cursor update
  renames that control, `--wait` will report `idle` while Composer is
  still generating. To re-derive the current name, dump Composer's
  AXButton descriptions while a generation is in flight (a small Swift
  walker over the Cursor AX tree filtering `role == "AXButton"`), find
  the stop/cancel control, and update the needle list in
  `~/dotfiles/bin/src/cursor-compose-status.swift`, then rebuild.
- Architecture details and AX-tree debugging notes:
  `~/dotfiles/docs/cursor-compose-ax-architecture.md`.
- `--dir` runs `cursor <dir>`, which briefly activates Cursor (the one
  focus-affecting step). Dispatching to an already-open repo is fully
  interference-free.
- Never send secrets in prompts; Composer requests go to Cursor's
  backend.
