---
name: application-error-contracts
description: Design, audit, implement, and test user-facing error contracts across application operation boundaries such as Server Actions, RPC handlers, HTTP routes, use cases, and UI consumers. Use when expected business failures are hidden as generic errors, arbitrary exception messages leak to users, stable error codes are lost between layers, result types allow impossible states, or an error-contract migration must be scoped end to end.
---

# Application Error Contracts

Keep expected failures as typed values and unexpected failures as exceptions. The boundary must be safe for users without making recoverable business failures indistinguishable from infrastructure faults.

## Start with the real operation graph

Trace every public operation from UI caller through action or route, use case, transaction, and infrastructure. Include wrappers, delegated actions, public-link routes, background callbacks, and alternate bulk/single-item paths. Do not infer completeness from one module or from a grep for `throw`.

Search for evidence of broken contracts:

- `error.message` comparisons or raw messages returned to clients;
- broad `catch` blocks that turn every exception into `{ success: false }`;
- typed `code`, `kind`, `reason`, or `status` fields converted back into plain `Error`;
- result objects with many optional fields and impossible combinations;
- UI code that branches only on HTTP status while ignoring a returned code;
- one layer writing `.kind` while the next reads only `.code`;
- replacement exceptions that discard the original stack or `cause`.

Record one row per operation: expected failures, current representation, public code, UI mapping, unknown-exception behavior, reporting owner, transaction boundary, and test coverage.

## Classify before converting

| Failure class | Boundary representation | User-facing behavior |
|---|---|---|
| Validation or recoverable business rule | Serializable discriminated result with a stable code | Map code to actionable copy |
| Authentication, authorization, or not found | Stable status and, only when needed, a public code | Fixed safe copy |
| Conflict or stale state | Typed result with enough safe context to retry or refresh | Explain the recovery action |
| Infrastructure fault, bug, or violated invariant | Preserve and report the original exception; rethrow or return generic 5xx at the outer boundary | Generic failure only |
| Framework control flow such as redirect/not-found signals | Pass through according to the framework contract | Framework-owned behavior |

Do not cap public business errors at an arbitrary number. The allowlist is the closed union of supported operation outcomes, not a list of approved message strings. Never expose arbitrary `Error.message` merely to avoid a generic message.

## Define a serializable contract

Prefer the smallest existing discriminated-union pattern in the codebase:

```ts
type OperationResult<T, Code extends string> =
  | { ok: true; value: T }
  | { ok: false; error: { code: Code } };
```

Add safe structured fields only when the UI actually needs them. Keep display text out of the server contract unless localization or product requirements explicitly make server-owned copy necessary. Use exhaustive mappings such as `satisfies Record<ErrorCode, string>` so a new code cannot silently fall through.

Do not introduce a generic error framework when a local union or typed domain error already works. Reuse existing `code`, `kind`, `reason`, and result types; normalize names only at the public boundary.

## Preserve exception and transaction semantics

- Convert only known typed failures to public results.
- Report unknown exceptions once, at the boundary that owns observability, with the original error intact.
- In Server Actions or RPC boundaries, rethrow unknown exceptions after reporting unless the framework requires a generic response.
- In HTTP routes, return a generic 5xx after reporting; do not serialize internal details.
- Preserve framework control exceptions rather than reporting or wrapping them as application faults.
- Verify that failed operations do not leave partial writes, counters, identifiers, or child records committed.

## Test the contract at the smallest reliable layers

Leave focused checks for:

1. each expected domain failure becoming its stable public code;
2. unknown exceptions being reported and rethrown or converted to generic 5xx;
3. every UI-visible code mapping to the intended recovery message;
4. transaction rollback for failures that occur after writes begin;
5. shared infrastructure callers retaining their existing external contract unless the change intentionally covers them.

Use lower-layer tests for serialization, mapping, and rollback. Add E2E only for behavior that depends on the real browser, navigation, framework transport, or a cross-system integration that lower layers cannot observe.

## Audit completion

Before claiming the migration is complete:

- compare the operation inventory with route/action exports and all callers;
- exercise both returned-failure and thrown-exception paths;
- verify every producer/consumer field name pair (`code`, `kind`, `reason`, `status`);
- identify unknown-exception handling on every outer boundary;
- rerun the inventory after implementation, because refactors can expose previously hidden paths.

Read [references/nextjs-operation-boundaries.md](references/nextjs-operation-boundaries.md) for the session-derived Next.js pattern and audit checklist.
