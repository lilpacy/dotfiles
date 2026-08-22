# E2E Timeout And Runner Provenance

Use this checklist when a remote GitHub Actions E2E run fails after a long wait, or when a rerun changes runner/provider.

## Timeout-source attribution

1. Find the exact failing assertion and the timeout value it used. Prefer the named helper constant over the expanded millisecond value.
2. Report the wait as a test budget first: "the assertion waited up to X seconds" is different from "the operation took X seconds."
3. Compare trace, network, server-action, database, and rendered UI evidence before assigning cause.
4. If backend work completed quickly and returned the expected state, but the DOM or screenshot stayed stale until the assertion timed out, classify the direct failure as stale client/UI observation, not backend slowness.
5. Do not increase the timeout unless measured evidence shows the operation eventually completes correctly and only the budget is too short.

## Rerun and runner provenance

1. Treat runner/provider selection as provenance, not an assumption from the command you ran.
2. Verify each attempt's runner from logs, for example setup-step names, image labels, provider-specific environment lines, or provider dashboard links.
3. If a runner override is created after workflow dispatch, assume it may not affect the already-created attempt until logs prove otherwise. Create the override before rerunning, then verify the new attempt.
4. Keep attempts separate in the report: original failure, attempted provider rerun, setup/runtime failure before tests, and final validation can all answer different questions.
5. Clean up temporary override variables after the attempt and state that cleanup in the final report.

## Report shape

Include a compact table with:

| Fact | Required evidence |
|---|---|
| Failing assertion | file, line, expectation, timeout constant |
| Operation duration | trace/network/server timing, if measured |
| Final observed state | screenshot, DOM, or structured trace payload |
| Runner/provider | log evidence for that specific attempt |
| Validation boundary | whether tests ran, setup failed, or only rerun infrastructure changed |
