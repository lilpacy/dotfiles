---
name: test-redundancy-judgment
description: Judge whether automated tests are redundant — whether a set of tests detects the same defect or distinct ones — and decide keep, consolidate, or remove. Use whenever deciding if tests overlap, after adding tests (post-Green consolidation), during test suite pruning, or when reviewing whether a new test duplicates existing coverage. This skill only judges; it does not orchestrate pruning campaigns or measure CI cost.
---

# Test Redundancy Judgment

Repository-declared testing rules take precedence; this skill is the generic fallback and must not weaken repo-specific protections.

Input: a set of tests and their scope. Output: `keep` / `consolidate` / `remove` per test. Nothing else — no workflow, no measurement, no batching. Callers (addition gates, pruning campaigns, reviews) compose this judgment into their own process.

## Evidence to compare

Two tests are duplicates only when ALL of these match. Textual similarity is not behavioral duplication.

- observable behavior and input partition
- public boundary or test layer
- assertion or oracle
- failure mode uniquely detectable at that boundary

## Judgment table

| Evidence | Action |
|---|---|
| Same behavior, partition, boundary, oracle, and failure mode as another test | Remove the more expensive or less diagnostic duplicate |
| Exhaustive partitions repeat at a higher layer while a smaller reliable boundary proves them | Keep exhaustive checks below; retain at most one minimal representative higher-layer wiring scenario |
| Same behavior but a different boundary exposes a distinct failure mode | Keep both |
| Different inputs that can only ever detect the same single defect | Consolidate (e.g., parameterize) or remove |
| Obsolete behavior confirmed against the current source of truth | Remove its tests |
| Expected behavior, equivalence, or provenance is uncertain | Keep and report the uncertainty |

## Protected categories

Keep, unless inspectable equivalent evidence covers the same risk, any test protecting: authorization, security, money, migration, concurrency, data integrity, data loss, or a recorded production incident.

## Invalid deletion evidence

- Line or branch coverage overlap alone. Tests sharing lines can still detect distinct defects when inputs, assertions, or failure modes differ.
- A test failing or being flaky. Never delete to make CI pass.
- Replacing deterministic assertions with weaker snapshots, mocks, or broader end-to-end checks does not count as preserving coverage.
- A test lacking an independent specification. That is characterization coverage — preserve it until the intended behavior is resolved.
