---
name: test-suite-pruning
description: Orchestrate a measured campaign to reduce an existing automated test suite — baseline CI cost, prune in small batches using redundancy judgment, and verify the cost actually improved. Use when the user explicitly asks to audit for redundant tests or to prune, reduce, deduplicate, consolidate, or rationalize existing tests to shorten CI. Do not use for ordinary feature work, adding tests, flaky-test diagnosis, or generic CI performance investigation.
---

# Test Suite Pruning

Reduce verification cost, not confidence. Fewer tests are a means; do not claim success until CI cost is measured. Whether any individual test is redundant is decided by the `test-redundancy-judgment` skill — this skill only orchestrates the campaign around that judgment.

## Establish authority and scope

1. Read repository instructions, specifications, test conventions, CI configuration, and representative tests.
2. Distinguish the requested operation:
   - For an audit, review, or report, produce candidates without editing files.
   - For an explicit prune, reduce, remove, deduplicate, consolidate, or optimize request, edit tests and test configuration within scope.
   - Do not change production behavior merely to make pruning easier unless the user separately requests it.
3. Identify the CI metric the user wants to improve: critical-path wall time, total runner time, or both.
4. Confirm from timings that tests are material to that metric. If setup, build, provisioning, queueing, or artifact work dominates, stop pruning and report the measured bottleneck.

## Measure the baseline

Prefer existing CI timing data. Otherwise run the repository-declared command under recorded, repeatable conditions.

Record:

| Metric | Baseline evidence |
|---|---|
| Test count | Discovered or executed count by layer/job |
| Critical-path time | Slowest required CI path or closest reproducible local proxy |
| Total runner time | Sum across affected jobs when available |
| Slow tests/jobs | Duration evidence, not filename-based guesses |
| Conditions | Commit, command, runner/environment, cache state |

Do not compare unlike commands, environments, cache states, or test selections. Repeat measurements only when observed noise could reverse the conclusion.

## Build a verification inventory

Derive expected behavior from specifications, requirements, incident records, API schemas, or other independent sources of truth. Treat implementation and existing tests as evidence, not as the sole specification when an independent source exists.

Assign stable IDs to atomic verification points, then map each candidate test to the evidence dimensions defined in `test-redundancy-judgment` (behavior/partition, boundary, oracle, unique failure mode), plus historical regression provenance and measured execution cost.

## Judge candidates

Apply the `test-redundancy-judgment` skill to each candidate. Its judgment table, protected categories, and invalid-deletion-evidence rules are the sole authority for keep / consolidate / remove — do not redefine or weaken them here.

Before editing, report the candidate ledger:

| ID | Test path and name | Verification point | Unique failure mode | Cost evidence | Proposed action | Confidence |
|---|---|---|---|---|---|---|

Use `remove`, `consolidate`, `move detailed partitions lower`, or `retain`. Cite exact files, test names, and evidence.

## Prune in small batches

1. Start with the highest-confidence candidates that affect the measured bottleneck.
2. Remove or consolidate the fewest tests needed to validate the hypothesis.
3. Run the narrow affected checks first, then the repository-required full verification.
4. Revert the batch if distinct behavior is no longer covered, diagnostics materially worsen, or required checks fail.
5. Continue only while each batch yields evidence toward the requested CI metric.

When one smaller test can replace many detailed higher-layer cases, add that test before deleting the higher-layer cases, then retain only the residual wiring scenario. Do not add a replacement when existing evidence is already sufficient.

## Verify the outcome

Measure under the baseline conditions and report:

| Result | Before | After | Change | Evidence |
|---|---:|---:|---:|---|
| Test count |  |  |  |  |
| Critical-path time |  |  |  |  |
| Total runner time |  |  |  |  |
| Required checks |  |  |  |  |

State separately:

- which verification responsibilities remain and where;
- which tests were removed or consolidated;
- whether CI improvement was directly measured, locally proxied, or still unverified;
- any retained candidates and the evidence preventing removal.

Do not claim success from test-count reduction alone. If confidence is preserved but CI time does not materially improve, keep or revert the change according to repository policy and report that pruning was not the effective lever.
