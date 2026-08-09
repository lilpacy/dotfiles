---
name: playwright-lazy-fixture-lifecycle
description: Diagnose and fix Playwright tests where a lazy per-test fixture is created after a beforeEach navigation, leaving the page with stale source data. Use when DB fixture prechecks pass but the browser cannot find the created entity.
---

# Playwright Lazy Fixture Lifecycle

Use this workflow when a Playwright test owns data through a test-scoped fixture, the database precheck succeeds, but the page loaded by a shared hook cannot see the created entity.

## Diagnose with evidence

1. Read the failing trace, screenshot, error context, and browser-side source data.
2. Confirm the entity exists through the fixture's database precheck.
3. Inspect which fixtures are requested by each hook and by the test body.
4. Treat a non-automatic fixture requested only by the test body as lazy. A shared `beforeEach({ page })` can navigate and fetch data before that fixture is resolved.
5. Verify the stale-snapshot hypothesis by comparing the created entity ID with the page's loaded data. Do not infer a product query bug from “entity not found” until this ordering is measured.

## Choose the smallest correct boundary

- If only one scenario needs the owned fixture, keep it lazy and refresh or navigate after the fixture resolves, before the first UI action.
- If a whole describe block needs it, request the fixture explicitly in the relevant hook.
- Use an automatic fixture only when every test in the scope truly requires its setup and teardown.
- Keep data creation, precheck, ownership, and teardown in the fixture. Keep navigation and UI readiness waits in the spec or its page-object/helper boundary.
- Do not weaken assertions, add retries, or add fixed waits. The fix is lifecycle ordering, not timing tolerance.

## Verify

1. Run the failing test without retries against a reset local database.
2. Confirm the owned entity is present in the browser-visible data before editing it.
3. Run the focused test repeatedly when the original symptom was intermittent.
4. Run the containing full CI or E2E workload to validate interaction with shared hooks and neighboring tests.
5. Record the failed run, root-cause evidence, focused Green result, and full-workload result.

## Common false lead

A successful database precheck proves fixture creation, not that a page loaded earlier has refreshed its read model. When the artifact shows old page data and the fixture is lazy, correct the navigation order before changing product queries.
