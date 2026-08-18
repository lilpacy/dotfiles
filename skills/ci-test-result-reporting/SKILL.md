---
name: ci-test-result-reporting
description: Design, implement, and review CI test-result parsers, flaky-issue fingerprints, PR comments, job summaries, artifacts, and required checks, and decide whether test-result automation belongs in CI or a human-directed agent workflow. Use when fingerprint fields mix test identity, reproduction variants, orchestration metadata, and occurrence locators; cancelled or timed-out runs are misreported as test failures; setup/global errors disappear because zero tests ran; diagnostics may expose stacks or payloads; workflow provenance limits what a run validates; or requests mix "AI detects" with CI automation.
---

# CI Test Result Reporting

Keep three facts separate: what the runner did, what tests observed, and whether policy allows the change to proceed. A trustworthy report preserves each fact instead of collapsing all non-success states into `failed`.

## Choose the automation owner first

Before editing a workflow, compare the operating models when a request mixes terms such as “AI detects,” “automatically file,” retries, or required checks.

| Model | Trigger and authority | Typical changes |
|---|---|---|
| CI-native | Every qualifying run; workflow owns retries and gating | Workflow, report parser, artifacts, required check |
| Human-directed agent | A human requests investigation or rerun; the agent interprets existing evidence | Agent skill and issue tooling; usually no CI change |
| Manual | A person reviews and files results | Documentation or checklist only |

Treat a conflict between these models as a design decision. Before creating a PR when their cost or enforcement differs materially, state the selected model and ask the user to choose explicitly. Record the trigger, actor, authority to rerun, gate effect, and persistence boundary.

If the human-directed model satisfies the need, reuse existing reports and issue tooling; do not add retries, workflow jobs, parser APIs, or required checks. If CI enforcement is explicit and confirmed, continue with the workflow below.

## Flaky issue identity and occurrence context

Before defining a flaky-test fingerprint or issue template, classify every candidate field by role.

| Role | Purpose | Persistence rule |
|---|---|---|
| Test identity | Names the logical test | Keep stable source-relative fields such as spec path and full title path |
| Failure identity | Groups the same failure mode | Keep a normalized failure signature whose normalization is explicit and tested |
| Reproduction variant | Distinguishes environments that can change behavior | Include only dimensions that actually vary, such as browser or device when a matrix exists |
| Occurrence locator | Finds one run's evidence | Store per occurrence; do not use in the deduplication key |
| Orchestration metadata | Schedules or selects tests | Exclude unless inspection proves it represents a stable reproduction variant |

Inspect runner configuration rather than inferring meaning from field names. A Playwright project may represent a browser variant, but it may instead encode spec selection, dependency order, or a generated stage counter. Omit constant dimensions from the issue contract; add them when the execution matrix starts varying and they become necessary for reproduction or deduplication. Keep run or job locators on each occurrence so artifacts remain discoverable.

Read [references/flaky-deduplication-contract.md](references/flaky-deduplication-contract.md) for a concrete Playwright classification and upgrade triggers.

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

## Full-to-partial E2E triage

When a full E2E run fails and the user authorizes investigation:

1. Preserve the application/test SHA, project, full test title, seed, dependencies, execution mode, and original artifacts.
2. Locate the last completed boundary in the original trace, video, screenshot, or server log. A top-level timeout alone does not identify the failed operation.
3. Reproduce the smallest equivalent partial at the same SHA, project, and test title. Record any unavoidable provenance difference such as omitted dependencies or a remote runner.
4. Classify `full fail -> equivalent partial pass` as only a flaky candidate until execution differences are excluded. Classify `full fail -> partial fail` as reproducible, even when the partial crosses the original timeout boundary and fails at the next assertion in the same flow.
5. Do not raise a timeout until measured evidence shows that the operation completes correctly and only the test budget is insufficient.

Treat optional local artifacts as resource costs. If video generation or a local production build makes the host unstable, disable optional video for every remaining local attempt in that investigation. If the build is still infeasible, switch to the repository's remote-partial procedure instead of repeatedly stressing the host. Preserve the requested artifact policy across reruns unless the user changes it.

When monitoring a long remote run, use the user's requested polling interval for both tool checks and status reports. Do not insert extra no-change updates between those intervals.

Read [references/full-to-partial-e2e-triage.md](references/full-to-partial-e2e-triage.md) for the validated shifted-boundary pattern and reporting checklist.

## Provenance and validation claims

A successful run validates only the code that the workflow executed. Some manual or dispatch workflows intentionally load workflow or reporter code from a default branch while checking out application tests from a pull-request head.

Before claiming an end-to-end validation, determine:

- which commit supplied the application and tests;
- which ref supplied the workflow definition;
- which ref supplied the parser and renderer;
- which version wrote the published artifact and PR comment.

If the run used an older reporter, describe the new reporter as contract-tested, not workflow-validated. Re-run after the new implementation is reachable only when that evidence is required.

## Required-check identity and workflow source

A red check run and a required check are different facts. A job's displayed name comes from the workflow source GitHub executed; enforcement comes from the applicable ruleset or branch-protection context. Never infer requiredness from the check color or a label such as `/ required`.

When a workflow uses `pull_request_target`, GitHub loads the workflow definition from the base branch. A pull request that renames or removes a job can therefore still show the old base-branch job on that same pull request. Checkout refs inside the job select code to inspect; they do not change which workflow definition GitHub loaded.

Diagnose three layers independently:

1. **Policy:** query effective branch rules and every applicable ruleset; record the required-status context, integration binding, ref condition, and enforcement state.
2. **Execution:** inspect the pull request's check rollup, workflow event, details URL, base/head SHAs, and the workflow file at both refs.
3. **Merge verdict:** inspect mergeability, merge state, reviews, unresolved threads, in-progress checks, and every required aggregate. A red optional job can coexist with a different real blocker.

Report the displayed check result, actual required context and policy source, current blocker, and the event after which a head-side workflow change will take effect. Read [references/github-required-check-source-and-identity.md](references/github-required-check-source-and-identity.md) for the verified command sequence and decision table.

A newer pull-request head does not automatically invalidate a prior E2E result. Compare the previously validated tree with the candidate tree and classify the semantic change. Re-run expensive E2E only when runtime code, build inputs, dependencies, schemas, fixtures, tests, or relevant integration configuration changed, or when repository policy explicitly requires it. A docs-only conflict resolution does not require full E2E when those documents are not executable inputs; run only the applicable documentation and policy checks.

Read [references/e2e-run-outcomes-and-provenance.md](references/e2e-run-outcomes-and-provenance.md) for the session-derived failure patterns behind these rules, and [references/post-validation-change-impact.md](references/post-validation-change-impact.md) for the post-validation rerun decision.

## Pull-request diff-range integrity

Keep the diff base and head in the same semantic domain. On a `pull_request` `synchronize` event, comparing the previous PR branch head (`github.event.before`) with GitHub's synthetic merge commit (`github.sha`) mixes new base-branch changes into the PR's incremental diff. This can falsely activate policy checks or demand documentation for files the PR did not change.

When a changed-file policy fails unexpectedly:

1. Read the job log's resolved base SHA, head SHA, and changed-file list.
2. Compare `github.event.before`, `github.event.pull_request.head.sha`, and `github.sha` rather than inferring their roles.
3. Confirm the real PR file list independently through the pull-request API.
4. Fix the workflow so an incremental PR range ends at `github.event.pull_request.head.sha`; reserve `github.sha` for validating the synthetic merge result.

If one stale `synchronize` run blocks an otherwise unchanged PR and changing the workflow is outside that PR's scope, a close-and-reopen cycle can trigger a non-`synchronize` pull-request run whose fallback base is the synthetic merge commit's first parent. Use this only after the user approves the exact external action and the workflow is known to run on `reopened`. After reopening, verify the head SHA, approval state, review threads, required checks, and merge state before merging. Never use an admin merge to hide the failed policy check.

## Diff-based ratchets

When a CI ratchet rejects newly added syntax, do not assume every required owner token appears in a `--unified=0` addition. Adding one property to an existing call may expose only that property line.

- Parse the new-line number from each hunk and associate it with every added line.
- Read the head revision's source and classify an added property by its enclosing construct. Ensure the checkout source actually matches the requested head revision.
- Keep the diff as the proof that the property is new; use the head source only for syntactic context so grandfathered code still passes.
- Test the existing-object insertion case, nested objects before the property, and an allowed sibling object with the same property name. A whole-call addition test alone does not cover the incremental case.

## Completion report

State the preserved raw outcome, rendered status, gate verdict, diagnostic exposure boundary, implementation provenance, and the strongest validation level actually achieved.
