# Auth System Refactor Plan

## Current State (Problems)

1. **Mixed auth paradigms** -- Session-based and token-based auth coexist with no clear boundary, making it unclear which mechanism is authoritative for any given request.
2. **No refresh tokens** -- JWTs likely have either a long expiry (security risk) or a short expiry that forces re-login (UX problem). There is no silent renewal path.
3. **Copy-pasted middleware across 15+ route files** -- Auth logic is duplicated, meaning a bug fix or policy change requires touching every file. Inconsistencies are guaranteed.
4. **No RBAC** -- Authorization is either absent or ad-hoc (`if (user.isAdmin)` scattered in handlers).

## Guiding Principles

- **One auth mechanism, applied once.** Every request passes through a single authentication gate before reaching any route handler.
- **AuthN vs AuthZ separation.** Authentication (who are you?) and authorization (can you do this?) are distinct layers.
- **Incremental migration.** The old system keeps working while the new one is built alongside it. No big-bang switchover.

---

## Phase 0 -- Audit & Catalog (1-2 days)

**Goal:** Know exactly what you have before changing anything.

| Task | Output |
|---|---|
| Grep every route file for auth-related code (`jwt.verify`, `req.session`, `req.user`, role checks) | Spreadsheet / markdown table of every auth touchpoint |
| Identify which routes use sessions, which use JWT, which use both | Classification list |
| Document current token lifecycle (where issued, expiry, storage, validation) | Short doc |
| List every "role" or permission check that exists today, even informal ones | Seed list for RBAC design |

**Why this matters:** You cannot centralize what you have not inventoried. Skipping this step is the #1 cause of refactors that break production.

---

## Phase 1 -- Centralized Auth Middleware (3-5 days)

**Goal:** Single source of truth for authentication.

### 1a. Create `src/middleware/authenticate.ts`

```
Request --> authenticate middleware --> req.user populated (or 401)
```

- Accepts a Bearer token from the `Authorization` header.
- Verifies the JWT signature and expiry.
- Attaches the decoded payload to `req.user`.
- Returns 401 on failure. No fallback to sessions yet (that comes in Phase 3).

### 1b. Apply globally via `app.use(authenticate)` early in the middleware chain

- Whitelist public routes (login, register, health, webhooks) using a simple array or a `@public` decorator pattern.

### 1c. Remove duplicated auth checks from each route file

- One file at a time. After each file, run existing tests (or manual smoke test if tests are sparse).
- Keep a checklist. Mark each of the 15+ files as migrated.

### 1d. Tests

- Unit test the middleware in isolation (valid token, expired token, missing token, malformed token).
- Integration test a protected route and a public route.

---

## Phase 2 -- Refresh Tokens (3-4 days)

**Goal:** Short-lived access tokens + long-lived refresh tokens.

### Design

| Token | Lifetime | Storage (server) | Storage (client) |
|---|---|---|---|
| Access token (JWT) | 15 min | Stateless (no DB) | Memory or `Authorization` header |
| Refresh token (opaque) | 7-30 days | DB table `refresh_tokens` | HttpOnly, Secure, SameSite cookie |

### Tasks

1. **Create `refresh_tokens` table** -- columns: `id`, `user_id`, `token_hash` (never store plaintext), `expires_at`, `created_at`, `revoked_at`.
2. **`POST /auth/login`** -- Issue both tokens. Store refresh token hash in DB.
3. **`POST /auth/refresh`** -- Validate refresh token, issue new access token (and optionally rotate the refresh token).
4. **`POST /auth/logout`** -- Revoke the refresh token (set `revoked_at`).
5. **Token rotation** -- On each refresh, invalidate the old refresh token and issue a new one. This limits the damage window if a refresh token leaks.
6. **Cleanup job** -- Periodic deletion of expired/revoked rows.

---

## Phase 3 -- Kill Session-Based Auth (1-2 days)

**Goal:** Remove the session layer entirely (assuming you want pure token-based auth).

1. Remove `express-session` (or equivalent) middleware.
2. Remove session store config (Redis/Mongo session store, etc.).
3. Grep for any remaining `req.session` references -- they should all be gone after Phase 1, but verify.
4. If any feature genuinely needs server-side state (e.g., CSRF for form submissions), handle it explicitly rather than via a general session.

**Alternative:** If you decide to keep sessions for browser clients and use JWTs for API clients, clearly document which path applies where and make the `authenticate` middleware handle both with a defined precedence.

---

## Phase 4 -- RBAC (3-5 days)

**Goal:** Role-based access control that is declarative, testable, and centralized.

### 4a. Data Model

```
users
  id
  ...

roles
  id
  name          -- e.g., "admin", "editor", "viewer"

user_roles
  user_id
  role_id

permissions
  id
  action        -- e.g., "posts:write", "users:delete"

role_permissions
  role_id
  permission_id
```

Start simple. If you only have 3-4 roles, a single `role` column on the `users` table is fine for now. Migrate to the full table structure when you actually need per-permission granularity.

### 4b. Authorization Middleware -- `src/middleware/authorize.ts`

```js
// Usage in routes:
router.delete('/users/:id', authorize('users:delete'), handler);
router.post('/posts', authorize('posts:write'), handler);
```

- `authorize(permission)` returns a middleware that checks `req.user.permissions` (or fetches from DB/cache) against the required permission.
- Returns 403 on failure.

### 4c. Populate Permissions on Login

- When issuing the access token, embed the user's permissions (or role name) in the JWT claims.
- For short-lived tokens this is acceptable. For long sessions, consider fetching from DB on each request (with caching).

### 4d. Tests

- Unit test: user with permission X can access route Y, user without it gets 403.
- Edge cases: user with no roles, user with multiple roles, permission inheritance if applicable.

---

## Phase 5 -- Harden & Clean Up (1-2 days)

| Task | Detail |
|---|---|
| Rate-limit auth endpoints | `express-rate-limit` on `/auth/login`, `/auth/refresh` |
| Helmet / security headers | Ensure `Strict-Transport-Security`, `X-Content-Type-Options`, etc. |
| Audit logging | Log all auth events (login, logout, refresh, failed attempts) |
| Secret rotation plan | Document how to rotate the JWT signing key without downtime (support multiple valid keys during rotation) |
| Remove dead code | Delete any leftover session config, old auth helpers, unused middleware |

---

## Suggested Order & Timeline

| Phase | Est. Duration | Can Be Parallelized? |
|---|---|---|
| 0 -- Audit | 1-2 days | No (do this first) |
| 1 -- Centralize middleware | 3-5 days | No (foundation) |
| 2 -- Refresh tokens | 3-4 days | No (depends on Phase 1) |
| 3 -- Kill sessions | 1-2 days | Yes, with Phase 2 |
| 4 -- RBAC | 3-5 days | Yes, with Phase 2 |
| 5 -- Harden | 1-2 days | After all above |

**Total: ~12-20 days** depending on test coverage and how tangled the current code is.

---

## Key Risks

1. **Breaking existing clients during migration.** Mitigate by running old and new auth side-by-side during Phase 1, with a feature flag or header to opt in to the new path.
2. **Missing an auth check during the copy-paste removal.** Mitigate by grepping exhaustively in Phase 0, and having integration tests that assert 401 on protected routes.
3. **Refresh token security.** Never store plaintext. Always hash. Always rotate. Always set HttpOnly + Secure + SameSite on the cookie.
4. **Scope creep.** RBAC can expand endlessly (permission inheritance, attribute-based access control, org-level scoping). Start with flat roles and permissions. Evolve only when a real use case demands it.

---

## Where to Start (literally)

1. Run `grep -rn "jwt\|jsonwebtoken\|req\.session\|isAuth\|isAdmin\|requireAuth\|checkAuth" src/` and catalog the results.
2. Create `src/middleware/authenticate.ts` with a clean JWT verification function.
3. Pick the simplest route file, swap its inline auth for the new middleware, and verify it works.
4. Repeat for the remaining 14 files.

That is your first week. Everything else builds on that foundation.
