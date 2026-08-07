---
name: external-auth-local-development
description: Diagnose, build, and verify local authentication environments that use third-party identity providers, custom local domains, nonstandard ports, or concurrent worktrees. Use when login callbacks or logout redirects reach the wrong origin, provider URL allowlists must be synchronized from environment configuration, local secret bootstrap fails, or a setup must be proven through a real browser round trip.
---

# External Auth Local Development

Treat local authentication as a distributed URL contract. An environment variable is only one input; correctness depends on the application, SDK, provider configuration, browser-visible origin, and concurrency model agreeing on exact values.

## Model the URL surfaces separately

Build this table from the repository and runtime before proposing a fix:

| Surface | Typical owner | Question to answer |
|---|---|---|
| Public application origin | Application environment | Which scheme, hostname, and explicit port does the browser use? |
| Login callback URI | Application plus provider allowlist | What exact URI is sent during authorization, and is it registered? |
| Logout return URI | Logout call plus provider allowlist | What exact absolute URI is sent when ending a session? |
| Application homepage or default fallback | Provider application settings | Is this a fallback, or does the application rely on it directly? |
| CORS origin | Provider allowlist | Which browser origin may call provider endpoints? |
| Internal server address | Local process manager or proxy | Must this remain invisible to redirects and cookies? |

Do not merge these surfaces because they happen to share an origin. Providers often store and validate them independently.

## Trace values end to end

For each surface, trace one concrete value through:

```text
environment/config
  -> repository setup script
  -> application or SDK wrapper
  -> final SDK argument / HTTP request
  -> provider-side registered value
  -> browser-visible redirect
```

Read the installed SDK or CLI version and the repository wrapper before relying on remembered provider behavior. Record scheme, hostname, port, and path exactly. Redact authorization codes, cookies, API keys, session IDs, and state parameters.

An environment variable does not update a provider allowlist by itself. Identify the script, CLI, API call, or documented manual operation that consumes it. If no consumer exists, the value changes only application behavior.

## Diagnose login and logout independently

For login failures:

1. Capture the authorization request's exact callback URI.
2. Compare it with the provider's registered callback URI.
3. Follow the callback response and application redirect without exposing query secrets.
4. Confirm that the external origin, not the proxy's internal port, survives every redirect.

For logout failures:

1. Inspect the application call that invokes logout.
2. Capture the final logout request and exact return URI.
3. Determine whether the provider validates a sign-out URI, uses an application homepage fallback, or applies another setting for the installed product/version.
4. Verify the browser's final location and local session-cookie state.

Do not infer the full cause from a provider error page alone. A provider-side setting and an incorrect SDK argument can produce the same visible symptom.

## Check provider synchronization

When local setup is intended to register URLs automatically:

- derive registered values from the same canonical local origin used by the application;
- inspect the actual provider API or CLI operation, including resource, HTTP method, application/environment scope, and error handling;
- make setup idempotent and surface synchronization failures explicitly;
- avoid overwriting unrelated provider settings unless the repository contract requires it;
- verify the provider-side value after synchronization rather than trusting a success message alone.

Re-check official documentation and installed tool source before encoding an endpoint or assuming that every URL surface has a public management API.

## Prove concurrent-worktree safety

A configuration that works for one worktree can still be wrong globally.

Before accepting the design:

1. Classify provider settings as per-request, per-session, per-environment, or singleton per application.
2. Model two simultaneous local origins, A and B.
3. Ask whether setup for B changes the logout or callback destination of an existing session on A.
4. Test both directions when the provider sandbox permits it.

Do not use a mutable singleton provider homepage as the sole return mechanism for concurrent worktrees unless cross-worktree redirection is an accepted constraint. Prefer a provider-supported per-request return value plus a stable allowlist rule when verified for that provider and version.

## Bootstrap local secrets safely

If the local setup owns development-only secret generation:

- generate only missing values;
- validate required length and format;
- preserve valid existing values;
- persist them only in the repository-designated ignored environment file;
- test first-run generation and repeat-run idempotence;
- log presence or validation status, never the secret value.

Do not copy production or another developer's secrets into a worktree merely to make authentication start.

## Test at the smallest reliable layers

| Contract | Minimum reliable evidence |
|---|---|
| Environment values are derived and persisted correctly | Setup-script test |
| SDK receives the exact callback or logout argument | Unit test around the application wrapper |
| Provider configuration synchronization uses the intended resource and scope | Mocked client test plus sandbox read-back when authorized |
| Cookies, provider session termination, and final browser location work together | Real browser round trip against a sandbox |
| Multiple local origins do not redirect into each other | Two-origin integration or browser verification |

Unit tests cannot prove provider allowlists or browser cookies. A single successful browser session cannot prove concurrent-worktree safety.

## Update documentation only after verification

Keep repository documentation declarative:

- define the canonical local origin and each URL surface;
- state which values setup synchronizes automatically and which remain external prerequisites;
- document secret bootstrap without exposing values;
- include troubleshooting checks that inspect actual runtime requests;
- avoid presenting an unverified workaround as the standard setup.

For WorkOS with Portless, read [references/workos-portless-observations.md](references/workos-portless-observations.md) before diagnosing or changing the setup. Treat version-specific observations as prompts to re-measure, not timeless provider guarantees.

## Completion criteria

Do not report the environment as fixed until all applicable checks pass:

- application and provider values match exactly, including explicit port and path;
- setup is repeatable from a fresh worktree without exposing secrets;
- login completes at the intended local origin;
- logout removes the local session and returns to the intended local origin;
- a second worktree cannot silently redirect the first one elsewhere;
- tests and canonical documentation describe the verified behavior.

## Pitfalls

- Changing an environment variable without finding the code that applies it to the provider.
- Declaring a Dashboard-only workflow before inspecting the provider CLI and management API.
- Updating a provider homepage and treating one successful logout as proof of multi-worktree correctness.
- Fixing the allowlist while leaving a relative or wrong-port SDK argument unchanged.
- Logging full callback URLs that contain authorization codes or state.
- Writing the setup guide before completing the real browser round trip.
