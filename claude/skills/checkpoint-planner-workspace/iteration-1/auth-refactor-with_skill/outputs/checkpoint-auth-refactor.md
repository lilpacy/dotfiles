# Checkpoint Plan: Auth System Refactor

**Created**: 2026-03-07
**Status**: Active

## Goal
Centralize the scattered JWT auth middleware into a single composable layer and add role-based access control (RBAC), without breaking existing routes during the transition.

## Constraints
- Production system serving live users -- zero-downtime migration required
- 15+ route files with copy-pasted auth checks that may have diverged over 3 years
- Session management is entangled with token-based auth in unknown ways
- No refresh token infrastructure exists today
- Team needs to keep shipping features during the refactor (can't freeze the codebase)

## What I Know
- Stack is Node.js/Express with JWT-based auth
- Auth was implemented ~3 years ago
- Auth checks are copy-pasted across 15+ route files
- Session management is mixed in with token-based auth
- No refresh tokens exist
- The desired end state includes centralized middleware + RBAC

## What I Don't Know
- [CRITICAL] Which routes rely on session-based auth vs. token-based auth, and whether any flows (OAuth callbacks, admin panel, websockets) depend specifically on sessions
- Whether the 15+ copy-pasted auth checks are identical or have diverged into subtly different variants over time
- What roles/permissions the system actually needs (who are the user types, what can each do?)
- Whether existing JWTs carry any role/permission claims already
- How tokens are currently issued, validated, and where the secret(s) live
- Whether any external services or clients depend on the current auth contract (headers, cookie names, token format)
- What the test coverage looks like for auth-related behavior

## First Proof (Checkpoint 1)
**Audit the current auth landscape.** Before writing any new code, map what actually exists:
1. Grep all 15+ route files and catalog every auth check variant
2. Determine which routes use sessions vs. tokens vs. both
3. Identify all places where tokens are issued or validated
4. Document the actual role/permission needs by route

**Passing looks like**: A single document (or spreadsheet) that lists every route, its current auth mechanism, and the permission level it should have. No code changes yet. This is pure discovery.

**Why this is the first checkpoint**: The biggest risk is hidden coupling between sessions and tokens. If you start writing a centralized middleware before understanding the variants, you'll break things you didn't know existed. The audit is cheap and makes every subsequent decision better-informed.

## What Could Make This Plan Wrong
- The session-based auth might be load-bearing for critical flows (OAuth, SSO, admin) -- removing it could be a bigger project than expected
- Some copy-pasted auth checks may have accumulated business logic beyond pure auth (rate limiting, logging, feature flags) that must be preserved
- External clients or mobile apps may depend on specific auth behavior (cookie names, header formats) that can't change without coordination
- The "refactor" might actually need to be a "rewrite" if the token issuance and validation logic is fundamentally broken or insecure

## Dependencies
- Access to all route files and middleware source code
- Knowledge of which user roles exist in the database today
- Understanding of any external consumers of the auth API (mobile apps, third-party integrations)
- Agreement from the team on the target RBAC model (roles, permissions, hierarchy)

## Edge Cases
- Routes that use both session AND token auth simultaneously
- Auth checks that have been modified to include business logic (not pure auth)
- Websocket connections that may authenticate differently
- Background jobs or cron endpoints with service-to-service auth
- Token expiration handling (currently no refresh tokens -- what happens when tokens expire?)
- Admin/superuser bypass patterns that may exist informally

## Checkpoints
| # | Checkpoint | Pass Criteria | Review? |
|---|-----------|--------------|---------|
| 1 | Auth audit complete | Every route cataloged with its auth mechanism, variants documented, role needs identified | Yes |
| 2 | Centralized middleware prototype | Single middleware handles auth for 1 route file, old and new produce identical behavior | Yes |
| 3 | Migration of all routes | All 15+ route files use centralized middleware, zero behavioral change, tests pass | Yes |
| 4 | Session cleanup | Session-based auth removed where unnecessary, session-dependent flows handled explicitly | |
| 5 | RBAC layer added | Roles and permissions enforced through middleware, tested per route | Yes |
| 6 | Refresh token support | Refresh token flow implemented, old token-only flow deprecated | |

## Review Point
**Review after Checkpoint 1** (the audit). This should take 1-2 days max and represents roughly 10-15% of the total effort.

Questions to ask at review time:
- Did we find any auth variants we didn't expect?
- Are sessions actually needed for anything, or are they dead weight?
- Is the RBAC model clear enough to implement, or do we need more input from stakeholders?
- Is incremental migration feasible, or do the variants force a big-bang switch?

## Definition of Done
- All auth checks go through a single centralized middleware
- RBAC is enforced at the middleware level with clear role definitions
- Session-based auth is either removed or explicitly justified where kept
- Refresh token flow is implemented
- All existing tests pass, new tests cover the centralized middleware and RBAC logic
- No copy-pasted auth code remains in route files
- Migration is documented for the team
