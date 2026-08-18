---
name: test-addition-gate
description: Gate every automated test addition on a distinct regression it alone would detect, and consolidate after Green. Use before writing or adding ANY test — unit, integration, component, or E2E — including during TDD, bug-fix regression tests, and "add tests for X" requests, even when the user did not ask about test quality. Also defines how coverage numbers may and may not be used.
---

# Test Addition Gate

Repository-declared testing rules take precedence; this skill is the generic fallback and must not weaken repo-specific protections.

AI-generated tests trend toward volume: many tests that all detect the same defect, or no realistic defect at all. Each test must pay for its maintenance by detecting a distinct, realistic regression. This skill gates the decision to add; layer placement, naming, and suite-wide pruning are separate skills.

## Before adding a test

1. Run the relevant existing tests with the repository's official command.
2. Search existing tests, fixtures, factories, stubs, mocks, and helpers for the behavior.
3. State one realistic regression that only the new test would detect. Different inputs that detect the same defect do not justify a separate test.
4. Prefer extending an existing test or parameterizing (`it.each` / `test.each` or the framework equivalent) when readability holds.
5. If you cannot state a distinct regression risk, do not add the test — report why instead.

## Do not test

- private methods, internal call order, or implementation steps
- framework/library default behavior
- trivial getters, defaults, re-export identity
- a mock's pass-through of itself
- behavior another layer already detects equivalently
- anything whose only justification is raising a coverage number

Mock only at boundaries that require isolation: network, external services, time and randomness, heavy or nondeterministic resources. Use real repository-owned code when it is cheap and deterministic.

## Coverage is diagnostic only

Coverage locates unverified high-risk contracts, meaningful branches, and boundary conditions. It is not a quality target, not a reason to add a test, not grounds to delete one, and not a CI gate. An uncovered line without an explainable distinct regression gets no test. If the user explicitly sets a coverage target, follow their instruction — but surface this policy once first.

## After Green

- Restate the distinct regression each new test detects.
- Judge new tests against existing ones with the `test-redundancy-judgment` skill; consolidate or remove tests that detect the same defect.
- Never simplify away tests protecting the categories that skill lists as protected.
