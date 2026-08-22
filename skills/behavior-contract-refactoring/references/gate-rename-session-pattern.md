# Gate Rename Session Pattern

This note captures a reusable pattern from a session where a behavior gate and its name were both wrong. It intentionally omits repository identifiers, PR numbers, raw logs, credentials, and business data.

## Pattern

A batch pipeline had a helper whose name implied automatic final confirmation. Reading the use case showed the helper really decided whether to create a review draft with a resolved vendor identifier. The user clarified that the desired gate was only "is a vendor identifier resolved"; score, bank/account comparison, warnings, and registration comparison were review evidence, not draft-creation blockers.

## Working Approach

1. Answer the semantic questions first: what the old term meant, where the state moved in the UI, and how multi-item inputs affected the status.
2. Convert the user correction into a decision table before editing.
3. Rename the rule to the real business action rather than keeping the misleading "automatic confirmation" term.
4. Delete compatibility exports when all callers are updated in the same change.
5. Keep diagnostics in logs/UI payloads while removing them from the gate.
6. Update current-state docs and scenario docs that still describe the old gate.
7. Search for old terms after tests pass; a post-commit review can catch stale wording in messages or docs.

## Checks That Mattered

- Domain test: identifier present passes even when score or review diagnostics are non-perfect.
- Use-case test: draft creation still happens through the real caller.
- Log/return-shape test: renamed payload remains safe and structured.
- Term search: old helper/function/field names and misleading prose are gone from current code and current-state docs.

## Avoid Capturing

Do not copy specific invoice records, log lines, object keys, account names, credential paths, or one-off staging commands into the skill. Those are environment facts, not durable workflow guidance.
