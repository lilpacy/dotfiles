---
name: ci-test-result-reporting
description: Design, implement, and review CI test-result parsers, PR comments, job summaries, artifacts, and required checks. Use when cancelled or timed-out runs are misreported as test failures, setup/global errors disappear because zero tests ran, diagnostics may expose stacks or payloads, or workflow provenance limits what a run actually validates.
---

# CI Test Result Reporting

Keep three facts separate: what the runner did, what tests observed, and whether policy allows the change to proceed. A trustworthy report preserves each fact instead of collapsing all non-success states into `failed`.

## Result model

Model execution outcome and gate verdict independently.

| Execution outcome | Report as | Required gate default |
|---|---|---|
| `passed` | Tests completed successfully | Pass only when every required condition is satisfied |
| `failed` | Tests ran or setup failed | Fail |
| `cancelled` | Run was interrupted | Fail, but never label it a test failure |
| `timed_out` | Run exceeded its limit | Fail, but keep timeout distinct from assertions |
| `no_results` or unknown | Result is unavailable | Fail safely unless an explicit contract says otherwise |

Preserve the runner's raw outcome in the artifact. Derive display status and required-check verdict separately.

## Workflow

1. Inventory every result source: runner exit, workflow conclusion, structured test report, top-level errors, artifact metadata, and required-check input.
2. Define one explicit mapping from raw outcomes to display status and another from outcomes to gate verdict.
3. Parse suite-level and setup/global errors even when no test case exists. A report that says “0 failed tests” must not hide the error that prevented discovery or setup.
4. Limit public diagnostics to the smallest useful summary. For multiline top-level errors, publish the first line; keep the full trace in access-controlled artifacts and logs.
5. Render counts only when they describe collected tests. Do not infer “no failures” from an empty test array.
6. Record provenance for the tested application/test SHA, workflow definition, reporting script, and artifact schema.
7. Verify the smallest contract tests, then exercise the real workflow only when the implementation under review can actually execute there.

## Minimum contract checks

Leave one focused automated check for each changed branch:

- `cancelled` remains visible as `cancelled` while the required gate rejects it;
- a setup/global error is visible when zero tests ran;
- a multiline top-level error exposes only its first line in comments and committed reports;
- existing passed and failed mappings remain unchanged;
- unknown outcomes fail safely.

Do not add retries, longer timeouts, or environment changes merely because reporting exposed an external or transient failure. First establish recurrence and measure the failing boundary.

## Provenance and validation claims

A successful run validates only the code that the workflow executed. Some manual or dispatch workflows intentionally load workflow or reporter code from a default branch while checking out application tests from a pull-request head.

Before claiming an end-to-end validation, determine:

- which commit supplied the application and tests;
- which ref supplied the workflow definition;
- which ref supplied the parser and renderer;
- which version wrote the published artifact and PR comment.

If the run used an older reporter, describe the new reporter as contract-tested, not workflow-validated. Re-run after the new implementation is reachable only when that evidence is required; do not repeat an expensive full suite for a wording-only documentation change.

Read [references/e2e-run-outcomes-and-provenance.md](references/e2e-run-outcomes-and-provenance.md) for the session-derived failure patterns behind these rules.

## Diff-based ratchets

When a CI ratchet rejects newly added syntax, do not assume every required owner token appears in a `--unified=0` addition. Adding one property to an existing call may expose only that property line.

- Parse the new-line number from each hunk and associate it with every added line.
- Read the head revision's source and classify an added property by its enclosing construct. Ensure the checkout source actually matches the requested head revision.
- Keep the diff as the proof that the property is new; use the head source only for syntactic context so grandfathered code still passes.
- Test the existing-object insertion case, nested objects before the property, and an allowed sibling object with the same property name. A whole-call addition test alone does not cover the incremental case.

## Completion report

State the preserved raw outcome, rendered status, gate verdict, diagnostic exposure boundary, implementation provenance, and the strongest validation level actually achieved.
