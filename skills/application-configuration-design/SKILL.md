---
name: application-configuration-design
description: Design and refactor application runtime configuration. Use when adding environment variables, stage selectors, feature/control values, public runtime constants, deployment-specific URLs, chain/network constants, or configuration docs; especially when deciding whether a value belongs in env, typed constants, provider-managed settings, or canonical documentation.
---

# Application Configuration Design

Application configuration should make deployment state explicit without turning every stable value into an environment variable. The default shape is one environment or stage selector plus typed constants for values that change only with that selector.

## First classify each value

Build a small table before changing config code:

| Value kind | Put it where |
|---|---|
| Secret, credential, token, private key | Environment variable or secret manager |
| Host-provided dynamic value, such as preview URL | Environment variable read at runtime |
| Stable per-stage public value | Typed constant selected by one stage discriminator |
| Value derived from another config value | Derived function, not another env var |
| Feature rollout changed without deploy | Feature flag or remote config |
| Provider-side allowlist or dashboard setting | Provider configuration plus docs/setup sync |

If a value is public and changes only because the app is in `production`, `staging`, or `local`, do not add a separate env var for it unless the repository already requires that shape.

## Prefer one selector

For stage-shaped configuration:

1. Define a narrow stage type, such as `production | staging | local`.
2. Define one typed configuration object for all stage-dependent values.
3. Create one constant per stage.
4. Select the object from one explicit discriminator, usually a single public env var in deployed production contexts.
5. Let local/test default to the local config without extra env setup.

This keeps config reviewable: changing a stage contract is a code diff, not a scattered deploy-dashboard edit.

## Validate the selector, not every constant

Validate untrusted env input at the boundary:

- accept only known stage names;
- fail clearly or use the repository's existing fallback behavior for unknown values;
- avoid indexing a loose map without handling the missing case;
- keep the resulting exported config typed as a complete object.

Stable constants should be type-checked by the language. Do not add runtime parsing or schema code for constants that are never read from outside the codebase.

## Keep env and docs aligned

Before editing docs or `.env` examples:

1. Find the repository's environment-variable source of truth.
2. Separate required external inputs from code-owned constants.
3. Remove obsolete env vars from examples only after code no longer reads them.
4. Document the one selector and the meaning of each stage.
5. If a provider or deployment platform supplies fallback values, name that source explicitly.

Do not snapshot current stage values in the skill. Read the repository code and docs each time.

## Framework notes

### Next.js and similar web apps

- Public client-visible values often need a `NEXT_PUBLIC_*`-style prefix; keep that set small.
- Server-only values do not need public exposure.
- Preview deployment URLs may be host-provided; derive `baseUrl` from the host value only for the stages that need it.
- Do not use `NODE_ENV` alone as the business stage. It usually means build/runtime mode, not `staging` versus `production`.

### Generated clients and SDKs

If configuration feeds generated code or SDK initialization, trace the final consumer before changing the shape. One selector is still preferred, but the selected object must expose the exact fields the consumer needs.

## Pitfalls

- Adding one env var per public constant because the value differs by deployment.
- Using `NODE_ENV=production` to mean both real production and staging.
- Duplicating derived values, such as base URLs, instead of deriving them from the canonical origin.
- Leaving docs that ask developers to set env vars that are no longer read.
- Treating provider dashboard settings as application env vars.
- Adding a generic config abstraction before there are multiple real consumers.

## Session references

- Read [references/single-stage-selector.md](references/single-stage-selector.md) for the user correction that motivated the one-selector rule.
