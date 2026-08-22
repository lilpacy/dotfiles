---
name: behavior-contract-refactoring
description: Use when changing an application behavior gate, decision rule, lifecycle state, return field, log field, or domain term whose current name no longer matches what it actually decides. This skill keeps semantic refactors coherent across code, tests, telemetry, documentation, and PR text, especially when the user corrects the intended business decision after seeing the existing code.
---

# Behavior Contract Refactoring

Use this when a code change is not just "change this condition" but "this concept is named or framed wrong." The goal is to make the durable contract match the real decision, with the smallest working diff.

Read [references/gate-rename-session-pattern.md](references/gate-rename-session-pattern.md) when the task resembles a gate being relaxed, renamed, and pushed through docs/tests/logs.

## Trigger Signals

- The user says a condition is too strict, too loose, misleading, or based on the wrong signal.
- The user asks "what does this term mean?" and the answer shows the name hides a different behavior.
- The implementation mixes a decision gate with diagnostics, warnings, score, review material, or UI state.
- A return field, log field, helper name, file name, or test description carries an old business term after the behavior changes.
- A reviewer or post-commit check finds obsolete wording rather than a code bug.

## Workflow

### 1. Identify The Actual Decision

Write the desired decision in one sentence before editing:

```text
When <input fact> is true, the system should <business action>; all other facts are <diagnostics/review material>, not gates.
```

Do not preserve the old abstraction until this sentence is clear. If the old name is still needed by another real caller, keep it; otherwise delete it instead of adding a compatibility wrapper.

### 2. Separate Gate Inputs From Review Evidence

Build a small decision table:

| Fact | Gate input? | Review evidence? | Notes |
|---|---:|---:|---|
| Stable identifier exists | Yes | Maybe | Usually the gate |
| Score/confidence | No, unless required | Yes | Prevents accidental fail-closed behavior |
| Warning/result detail | No, unless required | Yes | Preserve for UI/logs |
| External/account/bank metadata | No, unless required | Yes | Do not block drafts unless the user says it should |

Replace this table with task-specific facts. Do not generalize from the example.

### 3. Rename The Contract, Not Only The Helper

Search every public surface for the old term:

- file names and exported function/type names;
- return object properties;
- log fields and metric names;
- error messages and failure reasons;
- test names and fixture builders;
- canonical docs and scenario docs;
- PR template/body text.

If the name is wrong, rename the smallest stable contract that callers actually use. Avoid an alias for the old term unless an external consumer requires a deprecation window.

### 4. Keep Diagnostics Alive

Relaxing a gate should not delete useful review evidence. Move scores, warnings, comparisons, or account checks out of the gate and keep them available for logs, UI, or manual review when they already exist.

## Verification

Run the smallest check set that would catch a semantic drift:

- a domain/unit test for the new decision table;
- a caller/use-case test proving the business action still happens;
- a log/return-shape test when public telemetry changed;
- a docs/search pass proving old misleading terms are gone from current-state docs and code.

Use exact term searches for both old and new names. Treat matches in historical plans, old migrations, or release history as review prompts, not automatic failures.

## Pitfalls

### Keeping A Compatibility Alias For No Caller

An alias can preserve the misleading old concept. Delete the old helper when all callers are in the same change and no external API contract depends on it.

### Letting Review Evidence Re-Become A Gate

Scores, warnings, and comparison statuses often look authoritative. If the user says the gate is only an identifier or state, tests should fail when those diagnostics block the action again.

### Updating Code But Not Docs

Behavior gates often appear in design docs, scenario tests, operational runbooks, and PR templates. Search current-state documentation for the old term after code tests pass.

### Renaming Without Updating Telemetry Consumers

Log fields and metrics may be operational contracts. If renamed, call out the change in the PR and preserve safe summaries. If external dashboards depend on the old name, ask before removal.

## Completion Report

State:

- the old concept removed or renamed;
- the new decision source;
- which checks passed;
- any intentionally retained old wording and why.
