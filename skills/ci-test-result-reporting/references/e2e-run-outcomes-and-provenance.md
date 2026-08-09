# E2E run outcomes and reporter provenance

These patterns were verified while diagnosing a pull-request E2E workflow and are intentionally generalized.

## Cancelled run misreported as failure

The artifact retained `outcome: cancelled`, but a normalization step converted it to `status: failed`. The PR comment then reported a failed suite with zero tests. The correction was to preserve `cancelled` as a display state while continuing to reject it at the required gate.

## Global setup error with zero collected tests

A network failure in authentication setup stopped the suite before specs ran. The structured report contained a top-level error, but the renderer only inspected test failures, so the PR comment showed no failing tests. Parse run-level errors independently of test-case arrays.

Top-level messages can contain multiple lines, stacks, or arbitrary payload text. Publishing only the first line restored diagnosis without creating a new path for full traces or payloads to reach comments and committed reports.

## Reporter code came from another ref

A manually dispatched workflow tested the pull-request application head but intentionally used the default branch's reporting script as a trust boundary. The full suite proved the application head still passed; it did not exercise the new reporter. Parser tests supported the reporting contract, but live workflow validation remained pending until the reporter became reachable from the trusted ref.

Always record both the tested-code ref and the reporting-code ref before stating what a successful run proved.
