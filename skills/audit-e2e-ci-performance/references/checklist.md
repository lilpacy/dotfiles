# E2E-inclusive CI audit checklist

Evaluate every item with the ID shown. Do not omit an item because evidence is unavailable; use `UNKNOWN` or `N/A`.

## A. Baseline and critical path

- `A-1` PR CI p50/p95 wall-clock is observable.
- `A-2` Wall-clock can be separated into queue, setup, test, and report/artifact work.
- `A-3` Sharded workflows expose the slowest shard, not only averages.
- `A-4` The required-job DAG and end-to-end critical path are known.
- `A-5` Wall-time improvement is evaluated alongside total runner time or cost.
- `A-6` The current bottleneck has measured evidence rather than a configuration-based guess.

## B. Test layers and E2E volume

- `B-1` E2E covers only important browser-only flows and integration boundaries.
- `B-2` Validation, calculation, state partitions, and API contracts are exhaustively checked below E2E where equivalent confidence exists.
- `B-3` The same behavior is not redundantly partitioned across multiple layers without a distinct failure mode.
- `B-4` Fixture and prerequisite data is not created through unnecessary UI flows.
- `B-5` Uncontrolled third-party services are not contacted in every E2E run.
- `B-6` PR, main, nightly/release, and acceptance suites have explicit and distinct purposes.
- `B-7` PR browser/project matrices avoid combinations without an evidenced requirement.

## C. Isolation, authentication, and data

- `C-1` Tests do not depend on execution order or another test's success.
- `C-2` Data, account, or namespace is isolated per test or parallel worker.
- `C-3` Parallel tests that mutate server state do not share one account unsafely.
- `C-4` Authenticated state is safely reused when valid, avoiding repeated login cost.
- `C-5` Cookies, tokens, and authentication state are absent from the repository and public artifacts.
- `C-6` Setup and teardown are idempotent and rerunnable after partial failure.
- `C-7` Cleanup and shared fixtures do not race.
- `C-8` Diagnostics distinguish missing test data from product defects.

## D. Determinism and flakiness

- `D-1` State-based waits replace fixed sleeps.
- `D-2` Auto-wait and web-first assertions replace instantaneous DOM reads.
- `D-3` Locators prefer role, accessible name, label, or deliberate test IDs.
- `D-4` Time, randomness, locale, timezone, browser/dependency versions, and external APIs are controlled where relevant.
- `D-5` First failures preserve sufficient trace, screenshot, console, network, video, and server evidence.
- `D-6` Gating retries do not hide flaky failures.
- `D-7` Diagnostic retry-passes remain visible and tracked as flaky.
- `D-8` Quarantine has an owner, issue, expiry, and exit condition.
- `D-9` Non-idempotent POST/PATCH failures are not retried blindly.

## E. Reducing the execution set

- `E-1` When full execution is a material cost, a dependency graph or explicit impact map can select affected tasks/tests. Otherwise classify this `N/A` with timing evidence.
- `E-2` Shared configuration, dependencies, and test-infrastructure changes are included in impact analysis.
- `E-3` Unknown changes, analysis failure, and truncated change lists fail open to full execution.
- `E-4` Heuristic selectors such as Playwright `--only-changed` do not permanently replace required full verification.
- `E-5` PR selection is complemented by a full main, nightly, or release path.
- `E-6` Test, CI configuration, and dependency lockfile changes select a safe scope.
- `E-7` Logs expose why tests were skipped and which tests were selected.

## F. Caching

- `F-1` Package download caches use deterministic keys such as lockfile, OS, and runtime.
- `F-2` Build/test outputs are cached only when inputs and outputs are deterministic.
- `F-3` Cache hits, misses, restores, and saves are observable.
- `F-4` Restore time is measured as lower than regeneration or download time.
- `F-5` Scope, permissions, and keys mitigate stale caches and cache poisoning.
- `F-6` Caches contain no secrets, authentication state, or personal data.
- `F-7` Browser-binary caching is measured rather than assumed beneficial.
- `F-8` Non-deterministic E2E results are not reused to bypass verification.

## G. DAG and job structure

- `G-1` Independent tasks run in parallel and dependent tasks respect the DAG.
- `G-2` Unnecessary serial dependencies and oversized jobs do not extend the critical path.
- `G-3` Checkout, install, and service-start duplication caused by job splitting is measured.
- `G-4` Deterministic build artifacts are safely reused instead of rebuilding identically in downstream jobs.
- `G-5` New PR revisions cancel obsolete runs with an appropriate concurrency group.
- `G-6` Concurrency groups do not accidentally cancel other branches or workflows.
- `G-7` Failure artifacts remain available without excessive retention.

## H. In-runner workers

- `H-1` Worker count considers CPU, memory, database pools, test data, external APIs, and service capacity.
- `H-2` Wall-clock and failure rate were compared before and after worker changes.
- `H-3` CPU saturation/run queue/PSI, OOM, HTTP 5xx, database waits, and endpoint latency are observable where relevant.
- `H-4` Worker count does not exceed runner capacity without evidence.
- `H-5` Light and heavy tests can use different parallelism when resource profiles differ.
- `H-6` Worker count is a simple tunable that can be reduced when contention appears.

## I. Multi-job sharding

- `I-1` Isolation and obvious single-runner waste were addressed before sharding.
- `I-2` Test execution, not setup, was measured as the dominant cost before sharding.
- `I-3` Wall-clock, total runner time, and cost are compared across shard counts.
- `I-4` Slowest-shard imbalance is measured.
- `I-5` Long specs do not defeat count-based balancing.
- `I-6` Historical-duration balancing or spec splitting is used when measured imbalance justifies it.
- `I-7` Shard reports merge without missing results.
- `I-8` Shard failures preserve aggregate status and failure evidence.
- `I-9` Small or medium suites are not sharded without measured benefit.

## J. CI lanes and failure operations

- `J-1` PR is a fast required gate while main/nightly/release owns broader regression coverage.
- `J-2` PR browser reduction has a later lane for other required browsers.
- `J-3` Fail-fast policy matches the lane: fast gate versus collect-all acceptance regression.
- `J-4` Failures can be classified as flaky, product regression, missing test data, or infrastructure failure.
- `J-5` Failure classes have owners and response paths.
- `J-6` For materially slow or variable CI, runtime regressions have an observable threshold or continuous monitoring. Otherwise classify this `N/A` with timing evidence.
- `J-7` For materially slow, flaky, cached, or sharded CI, relevant p95, flaky rate, cache value, and slowest-shard trends can be tracked over time. Mark inapplicable metrics `N/A` individually.

## Sharding decision table

| Observed condition | Default decision |
|---|---|
| Setup dominates | Do not add shards; reduce setup duplication first |
| Test execution dominates and tests are isolated | Evaluate sharding |
| Only the slowest shard dominates | Rebalance by duration or split long specs |
| More workers increase 5xx, DB waits, OOM, or latency | Reduce workers and find the constrained resource |
| Added runner cost exceeds the value of wall-time reduction | Retain the current shape |
