---
name: test-layer-classification
description: Classify specification-derived verification points into the smallest reliable test layers before implementing or changing behavior, then reclassify them from actual test evidence before adding system or E2E coverage. Use for feature work, behavior changes, bug fixes that change contracts, test planning, or requests to add or modify integration, system, browser, or E2E tests in any repository.
---

# Test Layer Classification

Allocate each observable behavior to the smallest-scope public boundary that provides equivalent confidence. Treat system and E2E tests as residual coverage for behavior that smaller reliable boundaries cannot prove, not as default acceptance-test destinations.

## Establish the repository contract

1. Read applicable agent instructions and repository testing rules.
2. Locate the specification sources for the requested behavior: requirements, issue text, design files, ADRs, API schemas, or other repository-declared sources of truth.
3. Inspect test configuration, scripts, representative tests, and CI to identify test layers the repository actually supports. Do not infer a layer only from directory names.
4. Use the repository's layer names. If it declares none, describe layers by observable boundary, such as pure function, module/service, persistence, protocol/contract, component, or system/E2E.
5. Record missing or contradictory sources instead of deriving expected behavior from the current implementation.

## Extract verification points

Turn the source of truth into atomic, externally observable verification points. Give each point a stable ID so the same set can be compared before and after implementation.

Separate detailed partitions such as branches, boundary values, invalid inputs, state transitions, persistence effects, protocol behavior, rendering and interaction, and cross-boundary wiring. Do not combine points that need different evidence.

## Select the smallest reliable boundary

Choose by equivalent confidence, determinism, and diagnostic precision rather than by a fixed framework hierarchy.

| Verification point | Prefer this boundary |
|---|---|
| Pure calculation, validation, branching, boundary values, or state transition | Pure function or domain/module public API |
| Orchestration, authorization decision, mapping, retries, or collaborator calls | Service/use-case public API with controlled collaborators |
| Query, mutation, transaction, constraint, serialization, or persistence semantics | Real persistence integration boundary |
| Request/response shape, status, headers, authentication protocol, or adapter contract | Protocol, contract, API, or adapter boundary |
| Conditional rendering, local interaction, accessibility semantics, or component state | Component or UI integration boundary |
| Process startup, framework/runtime wiring, real navigation, hydration, cookie/session behavior, upload/download, or a critical flow spanning boundaries that cannot be reproduced equivalently below | Minimal representative system/E2E scenario |

“Multiple modules participate” and “a system test could observe it” are not reasons to choose system/E2E. If detailed conditions can be proven below while only wiring remains uncertain, keep exhaustive partitions below and use at most one representative higher-level wiring scenario.

## Phase 1: preliminary classification

For behavior implementation or modification, output this table before editing production code:

| ID | Verification point and source | Planned smallest reliable boundary | Higher-level candidate reason | Planned evidence |
|---|---|---|---|---|
| `<stable ID>` | `<observable behavior and source location>` | `<repository layer and public boundary>` | `<residual risk or none>` | `<planned test location/name if known>` |

Use `none` when no higher-level residual exists. Mark missing test infrastructure or unavailable boundaries explicitly; do not silently promote their checks to E2E.

Implement the selected smaller-scope tests as the Red step, implement the behavior, and make those tests Green according to the repository workflow.

## Phase 2: evidence-based reclassification

After implementation and smaller-scope tests are Green, but before editing system/E2E tests, inspect the actual tests and output:

| ID | Expected behavior from source | Verified test evidence | Covered at a smaller reliable boundary? | Residual behavior requiring a higher layer | Final action |
|---|---|---|---|---|---|
| `<same ID>` | `<source-backed expectation>` | `<path, test name, and observed result, or none>` | `<yes/no>` | `<specific unproven behavior or none>` | `<existing test / add smaller test / minimal higher-level test / no test change>` |

Keep every preliminary ID unless the source of truth changed. If implementation reveals a new requirement, update the source of truth first and then add it to both classifications.

If a planned smaller-scope check is missing, add it and make it Green, then repeat Phase 2. Do not move missing lower-layer coverage into a higher layer. Add or modify a system/E2E test only for residual behavior that remains after this evidence review. If no residual remains, report that no system/E2E change is needed.

## Test-only requests

When asked only to add or modify tests for existing behavior, inspect the source of truth, implementation boundaries, and existing tests, then run Phase 2 before editing the requested high-level test. Use the result to decide whether to change an existing smaller-scope test, add missing smaller-scope coverage, retain a minimal high-level scenario, or make no test change.

## Guardrails

- Do not edit production code before Phase 1 is output for behavior-changing work.
- Do not edit system/E2E tests before Phase 2 is output.
- Do not derive expectations from implementation when an independent source of truth exists.
- Do not duplicate exhaustive branches, boundary values, or error partitions across smaller and higher layers.
- Do not choose E2E because a page lacks E2E coverage, a neighboring feature has it, or an existing suite can host it.
- Do not claim coverage without inspectable evidence. Planned tests are not verified tests.
- Do not invent repository commands, frameworks, test layers, or source-of-truth locations.
