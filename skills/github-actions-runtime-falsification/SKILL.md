---
name: github-actions-runtime-falsification
description: Investigate GitHub Actions runtime regressions by comparing recent runs, job and step durations, test counts, slow files, exact-SHA repeats, and critical-path effects. Use when CI or E2E feels slower, a suspected cause needs falsification, or optimization priorities must be ranked from observed run data.
---

# GitHub Actions Runtime Falsification

Treat runtime claims as hypotheses. Rank causes and mitigations by their effect on workflow wall time, not by the isolated cost of a step or test.

## Workflow

1. Fix the observation window and workflow names. Record the timezone and exclude in-progress runs.
2. Keep cohorts separate: success, failure, cancelled; full and partial suites; push, pull request, and dispatch when their scopes differ.
3. List runs with `gh run list --workflow <name> --created <range> --json ...`.
4. Read `repos/{owner}/{repo}/actions/runs/{id}/jobs` with `gh api`. Compute each job and step duration from `started_at` and `completed_at`.
5. For parallel jobs, workflow critical path is the slowest required job. Do not add parallel durations.
6. Read selected logs with `gh run view <id> --log`. Extract test-file and case counts, slow-file durations, worker counts, timeouts, and setup/global failures.
7. Prefer exact-SHA repeated runs with identical collected counts when testing environment variance. If only counts match, label code-content equality unproven.
8. State a falsifier before judging each hypothesis, then classify it as supported, contradicted, conditional, or unmeasured.

## Critical-path test

For a proposed removal or separate parallel job:

`benefit ceiling = current critical path - max(other required paths, separated work)`

An expensive test in a non-critical shard can have zero wall-time benefit. Compare every candidate against the competing shard or job before ranking it.

For serial steps in one job, model the observed chain explicitly. Splitting steps into parallel jobs is promising only when the combined serial chain is the critical path; include new job startup overhead in any final estimate.

## Falsification table

Report at least:

| Hypothesis | Falsifier | Observation | Verdict | Ranking effect |
|---|---|---|---|---|
| Suspected cause | Evidence that would disprove it | Run IDs and measured range | Supported / contradicted / conditional / unmeasured | Promote, demote, or retain as measurement |

Do not promote a mechanism to a cause when its cumulative time is not logged. Keep it as a measurement target.

## Failure runs

Analyze failure latency separately from successful-run performance. Count recurrence across comparable failed runs. A timeout cascade can justify fail-fast handling without explaining the happy-path regression.

## Provenance checks

Record the application/test SHA, workflow source, event, test scope, and collected counts. Manual workflows may execute workflow code from a default branch while testing another SHA. Do not claim exact equivalence without checking these boundaries.

## Completion

Return the observation window, cohort sizes, measured ranges and medians, strongest counterexample, revised cause ranking, revised action ranking, evidence links, and remaining unmeasured boundaries.
