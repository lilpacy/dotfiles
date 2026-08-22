# Single Stage Selector Correction

## Durable lesson

When a web app has public per-stage values, prefer one explicit stage selector and typed constants for the rest. Do not expand the environment-variable surface unless each added variable is independently secret, host-provided, or deploy-time mutable.

## Evidence from the session

The user rejected a direction that increased environment variables and asked for a shape equivalent to:

- a `Stage` union for `production`, `staging`, and `local`;
- a typed `Environment` object containing stage-dependent values;
- one constant object per stage;
- a mapping from selector to object;
- a single public selector env var for deployed production-mode builds;
- local/test selecting the local config by default.

Concrete product identifiers, addresses, and URLs from the session are intentionally omitted. Future agents must read the current repository's environment-variable documentation and config code for actual values.

## Apply this when

- adding or refactoring deployment config;
- replacing multiple public env vars;
- deciding whether a public value should become an env var;
- reviewing a config PR where `NODE_ENV` is being used as the only stage signal.

## Minimal implementation shape

```ts
type Stage = "production" | "staging" | "local";

type AppEnvironment = {
  stage: Stage;
  baseUrl: string;
  // other complete, typed stage-dependent values
};

const environments = {
  production: { stage: "production", baseUrl: "https://example.com" },
  staging: { stage: "staging", baseUrl: "https://staging.example.com" },
  local: { stage: "local", baseUrl: "http://localhost:3000" },
} satisfies Record<Stage, AppEnvironment>;

export const environment =
  environments[parseStage(process.env.NEXT_PUBLIC_APP_STAGE)] ?? environments.local;
```

Use the repository's existing naming, validation, and fallback conventions rather than copying this sketch verbatim.
