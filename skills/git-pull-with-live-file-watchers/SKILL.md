---
name: git-pull-with-live-file-watchers
description: Resolve Git pulls blocked because a running editor, sync client, metadata plugin, formatter, or other file watcher recreates local changes immediately after `git stash`. Use when a pull reports that local changes would be overwritten, a normal stash appears successful, and the same files become dirty again before the pull can run.
---

# Git Pull With Live File Watchers

Preserve the user's work, temporarily quiesce the verified writer, fast-forward the branch, and reapply the original changes without discarding unrelated stashes.

## Diagnose Before Mutating

1. Run `git status --short --branch` and `git diff --name-only --diff-filter=U`.
2. Run `git fetch --prune`, then compare local and upstream paths with `git diff --name-status HEAD..@{upstream}`.
3. Inspect local diffs. Distinguish an unresolved merge from a pull blocked by dirty files.
4. Create a named stash containing the affected local work. Do not include unrelated files unless required.
5. Immediately check status. If the same files reappear with new timestamps, hashes, workspace state, or formatting, treat a live writer as the cause.

Do not use `git reset --hard`, `git checkout --`, or broad cleanup commands to win a race against a watcher.

## Identify the Writer Safely

Resolve exact processes from executable paths. Prefer a process listing such as:

```sh
ps -axo pid=,comm=
```

Avoid loose `pgrep -f` matches: environment variables and command arguments can contain an application path and produce false positives.

Pause a process only when its ownership and relevance are clear and doing so is within the user's requested workflow. Otherwise ask the user to close or pause the application. Never terminate a process merely because its name resembles the writer.

## Preserve, Pause, Pull, Restore

1. Record the original named stash commit with `git rev-parse 'stash@{0}'`.
2. Resolve fresh, exact PIDs for the verified writer.
3. Install an EXIT/HUP/INT/TERM trap that sends `SIGCONT` before sending `SIGSTOP`.
4. Pause every relevant writer process. In zsh, use an array and `"${watcher_pids[@]}"`; a quoted scalar containing spaces is one invalid PID.
5. Stash any discardable churn that appeared after the original stash.
6. Run `git pull --ff-only`.
7. Apply the recorded original stash commit. Use `--index` only when the original staged state must be restored.
8. Run `git diff --check`, confirm `git diff --name-only --diff-filter=U` is empty, and confirm `HEAD` equals the upstream branch.
9. Drop only the two stashes created for this workflow, and only after their identities and restored diff are verified. Drop the older original entry before the newer churn entry so reflog positions remain predictable.
10. Resume the writer explicitly, then remove the trap.

Keep the trap active throughout the Git operations so any failure resumes the paused application.

## Verify After Resume

Run:

```sh
git pull --ff-only
git status --short --branch
git diff --name-only --diff-filter=U
git diff --check
git rev-parse HEAD
git rev-parse '@{upstream}'
```

If the application updates metadata after resume, report those new working-tree changes separately from merge conflicts. Do not silently discard them; they may be expected application state even though they were triggered by the pull.
