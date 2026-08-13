---
name: audit-e2e-ci-performance
description: Audit a repository's E2E-inclusive CI performance and reliability against evidence-based best practices, covering test-layer scope, isolation, determinism, affected selection, caching, DAG structure, worker tuning, sharding, CI lanes, and runtime observability. Use when asked to check, review, assess, or score whether an application follows E2E/CI speed best practices, especially before proposing CI optimizations. Default to a read-only audit; do not implement fixes unless separately requested.
---

# Audit E2E CI Performance

Judge the system by measured critical-path time, reliability, and runner cost. Do not equate more parallelism with better CI.

## Establish the audit boundary

1. Read applicable `AGENTS.md` files and repository instructions.
2. Inspect README and architecture/testing docs, package scripts, lockfiles, test configuration, CI workflows, and representative tests.
3. Trace actual workflow entry points to the commands and configurations they execute. A dormant config is not evidence.
4. Identify CI providers, PR-required workflows, main/nightly/release lanes, test layers, browser projects, workers, shards, runner sizes, caches, artifacts, and external services.
5. Read [references/checklist.md](references/checklist.md) completely and evaluate every item.

## Preserve read-only behavior

- Do not edit files, commit, push, rerun workflows, dispatch jobs, cancel runs, or write to external services.
- Prefer repository and existing CI evidence. Do not run build or test commands merely to manufacture a baseline.
- Use read-only `git`, `rg`, package-manager listing, `gh run list`, `gh run view`, and `gh api` operations when available and authorized.
- If CI history is inaccessible, mark runtime-dependent checks `UNKNOWN`; do not substitute intuition.
- If the user separately asks for fixes, finish and present the audit before changing anything.

## Build the evidence set

Record the audited commit, timezone, workflow names, event types, and observation window.

Keep incomparable cohorts separate:

- success, failure, and cancelled runs;
- PR, push, dispatch, and schedule events;
- full and selected suites;
- cache-hit and cache-miss runs;
- different runner classes or application/test SHAs.

For GitHub Actions, inspect recent runs and job/step timestamps. Prefer exact-SHA repeats with identical collected test counts when comparing environment variance. Cite run and job URLs.

Measure when evidence permits:

| Metric | Rule |
|---|---|
| PR wall-clock | `completed_at - created_at`; report p50 and p95 for a comparable cohort |
| Queue | first required job start minus run creation |
| Setup | checkout, install, browser/service startup, restore, and preparation steps |
| Test | observed test execution steps, preserving parallel structure |
| Critical path | slowest required dependency path; never sum parallel jobs |
| Sharded suite | `queue + setup + slowest shard + report merge` |
| Runner consumption | sum of comparable job execution durations |
| Flaky rate | retry-pass or classified flaky occurrences divided by comparable executions |
| Cache value | restore/save time compared with regeneration or download time |

Do not calculate percentiles from fewer than five comparable completed runs. Report the raw range and sample size instead.

## Apply the checklist

Use exactly these statuses:

| Status | Meaning |
|---|---|
| `PASS` | Inspectable repository or run evidence satisfies the item |
| `FAIL` | Evidence shows the item is missing, unsafe, or counterproductive |
| `UNKNOWN` | Required configuration, provenance, or measurement is unavailable |
| `N/A` | The item does not apply to this architecture, suite, or scale |

Rules:

- Cite `path:line`, a test name, or a CI run/job URL for every `PASS` and `FAIL`.
- Explain the applicability reason for every `N/A`.
- State the missing observation needed to resolve every material `UNKNOWN`.
- Do not award `PASS` because a tool, option, or file merely exists.
- Do not assign `FAIL` merely because an optimization is absent. Use `N/A` when measured full execution is already cheap, safe, and outside the critical bottleneck; cite the measurement and the threshold that would make the item applicable.
- Do not treat supported hosted-runner labels or official action major tags as failures by themselves. Require a repository pinning policy, observed drift, reproducibility failure, or an explicit threat model; otherwise record the boundary as `UNKNOWN` or a non-blocking risk.
- Treat dedicated runtime trend infrastructure as scale-dependent. Existing provider timestamps can be sufficient for a small, consistently cheap workflow; require automation only when regression detection is materially difficult or an SLO exists.
- Treat Playwright `--only-changed` and similar heuristics as early-feedback selectors, not proof that later full verification is unnecessary.
- Treat browser-binary caching as conditional: compare restore time with download/install time.
- Treat retries as diagnostic only when first failures and retry-passes remain visible and tracked.
- Evaluate worker count against CPU, memory, database pools, test data, external APIs, and service capacity.
- Recommend sharding only when test execution dominates setup, tests are independent, and measured wall-time benefit justifies added runner cost.

## Rank findings

Rank only findings that can materially affect critical-path time, runner cost, regression detection, or flakiness. Keep unmeasured ideas as measurement targets.

For each proposed improvement, identify:

1. root cause;
2. smallest change that could address it;
3. expected metric affected;
4. falsifier or verification method;
5. evidence threshold required before adoption.

Return at most five improvements. Prefer deletion, native CI features, repository patterns, and already-installed dependencies. Do not propose new orchestration products without evidence that simpler rungs fail.

## Report

Start with one paragraph stating whether the CI follows the practices, which conclusion is measurement-limited, and the dominant observed bottleneck.

Then return:

| ID | Status | Check | Evidence | Impact |
|---|---|---|---|---|
| `A-1` | `PASS/FAIL/UNKNOWN/N/A` | Checklist item | `path:line` or run URL | Critical-path, cost, confidence, or reliability effect |

Include every checklist item, followed by:

### Measured summary

| Metric | Current value | Evidence | Measurement needed if unknown |
|---|---:|---|---|
| PR wall-clock p50/p95 | | | |
| Queue | | | |
| Setup | | | |
| Test | | | |
| Slowest shard | | | |
| Report merge | | | |
| Runner consumption | | | |
| Flaky rate | | | |
| Cache hit rate/value | | | |

### Priority improvements

| Priority | Root cause | Minimum change | Expected effect | Verification | Adoption threshold |
|---:|---|---|---|---|---|

Finish with separate lists for immediate failures, measurement-first questions, justified current-state decisions, and human decisions. Explicitly state that the audit made no changes.
