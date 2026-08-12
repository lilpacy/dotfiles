---
name: test-suite-pruning
description: Audit and reduce an existing automated test suite by removing redundant verification only when equivalent confidence remains, then measure whether the change improves CI runtime. Use when the user explicitly asks to audit for redundant tests or to prune, reduce, deduplicate, consolidate, or rationalize existing tests to shorten CI. Do not use for ordinary feature work, adding tests, flaky-test diagnosis, or generic CI performance investigation.
---

# Test Suite Pruning

Reduce verification cost, not confidence. Treat fewer tests as a means; require distinct behavior and failure modes to remain covered, and do not claim success until CI cost is measured.

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

Assign stable IDs to atomic verification points. Map every candidate test to:

- observable behavior and input partition;
- public boundary or test layer;
- assertion or oracle;
- failure mode uniquely detectable at that boundary;
- historical regression or critical-risk provenance;
- measured execution cost.

If no independent expectation exists, classify the test as characterization coverage and preserve it unless the user resolves the intended behavior.

## Apply the deletion gate

Classify each candidate with this table:

| Evidence | Action |
|---|---|
| Same behavior, partition, boundary, oracle, and failure mode as another test | Remove the more expensive or less diagnostic duplicate |
| Exhaustive partitions repeat at a higher layer while a smaller reliable boundary proves them | Keep exhaustive checks below; retain at most the minimal representative higher-layer wiring scenario |
| Same behavior but a different boundary exposes a distinct failure mode | Keep both |
| Obsolete behavior is confirmed by the current source of truth | Remove its tests |
| Test protects authorization, security, money, migration, concurrency, data integrity, data loss, or a recorded production incident | Keep unless inspectable equivalent evidence covers the same risk |
| Expected behavior, equivalence, or provenance is uncertain | Keep and report the uncertainty |

Never use line or branch coverage alone as deletion evidence. Never delete a failing or flaky test merely to make CI pass. Do not replace deterministic assertions with weaker snapshots, mocks, or broader end-to-end checks.

## Produce the candidate ledger

Before editing, report:

| ID | Test path and name | Verification point | Unique failure mode | Cost evidence | Proposed action | Confidence |
|---|---|---|---|---|---|---|

Use `remove`, `consolidate`, `move detailed partitions lower`, or `retain`. Cite exact files, test names, and evidence. Do not count textual similarity as behavioral duplication.

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
