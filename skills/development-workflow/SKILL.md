---
name: development-workflow
description: "Use for code implementation, bug fixes, refactors, and test additions. Enforces the user's development style: YAGNI, TDD, clear contracts, separation of concerns, no unsolicited fallback or backward-compatibility helpers, and maintainable code structure."
---

# Development Workflow

## Core Rules

- Apply YAGNI strictly. Do not plan, implement, or output work outside the requirement.
- Use TDD: explore -> Red -> Green -> Refactor.
- If KPI or coverage targets are given, keep iterating until they are met.
- Ask when instructions are unclear.
- Do not add fallback implementations or backward-compatibility helpers unless the user explicitly asks for them.

## Code Design

- Keep concerns separated.
- Separate state from logic.
- Prefer readable, maintainable code.
- Define contract layers strictly: APIs, types, schemas, and boundaries should be explicit.
- Keep implementation layers replaceable or regenerable where practical.
- Put statically checkable rules into the environment's linter, type checker, or ast-grep rules instead of relying on prompts.

## Control Flow

Prefer early returns and avoid nested `if` blocks:

```ts
function example() {
  if (condition1) return nearNormalCase1;
  if (condition2) return nearNormalCase2;

  try {
    return normalCase;
  } catch {
    throw abnormalCase;
  }
}
```
