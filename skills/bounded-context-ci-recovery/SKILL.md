---
name: bounded-context-ci-recovery
description: Recover CI jobs that fail because a bounded LLM context exceeds its byte budget. Use when a dry-run or scheduled workflow reports a context/catalog budget overflow and the job provides replayable input artifacts.
---

# Bounded Context CI Recovery

Recover the blocked input without silently dropping evidence.

## Procedure

1. Read the failed step log and download its artifacts.
2. Count the selected inputs, expand them with the production context builder, and measure the exact rendered byte size.
3. Identify whether growth came from new inputs, historical candidate retrieval, or related-page expansion. Do not assume schedule frequency is the root cause.
4. Add one behavior-level regression test that reproduces a context larger than the old limit but smaller than the proposed limit. Confirm Red.
5. Raise only the bounded total limit needed for the measured backlog, retaining per-page truncation and fail-fast behavior. Confirm Green.
6. Run the full relevant test suite and replay the failed artifact input locally against the changed builder.
7. Commit and review the change before push.
8. Push, run the workflow in dry-run mode, inspect its decision and preview diff, then run production only if the preview is scoped and valid.
9. If production creates a PR, treat recovery as incomplete until the PR is merged or closed and its finalized cursor record is written.

## Guardrails

- Never resolve overflow by taking the first N candidates or the first N bytes.
- Never infer provider capacity from bytes alone; dry-run is the downstream acceptance check.
- If the measured backlog does not fit with a modest bounded increase, stop raising the limit and partition work into independently validated groups.
- Do not merge generated content merely to advance the cursor; preserve the normal review boundary.
