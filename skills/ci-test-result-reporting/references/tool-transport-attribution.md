# Tool Transport Attribution

Use this when a CI or GitHub Actions investigation depends on a local CLI such as `gh`, but the agent's command runner fails before the command actually executes.

## Boundary Rule

Classify the failure by the deepest layer reached:

| Deepest reached layer | What failed | What not to claim |
|---|---|---|
| Agent/tool host negotiation | Agent transport to shell | Do not blame the CLI, GitHub, CI, credentials, or the user's machine |
| Shell startup | Local shell environment | Do not claim the target CLI or remote service failed |
| CLI emitted an error | CLI invocation, auth, arguments, or remote API | Quote the CLI error and keep remote-service claims conditional |
| Remote service returned data/error | GitHub/CI/service boundary | Diagnose from returned status, logs, and API payloads |

## Reporting Pattern

- Say which layer failed and which layers were not reached.
- If the user says the CLI works locally, accept that as compatible with an agent-transport failure.
- Ask for a minimal command output only after agent-side transport is blocked, and frame it as a workaround for the agent path rather than proof that the CLI is unavailable.

## Session-Derived Trigger

In a GitHub Actions run investigation, the agent initially implied `gh` was unavailable. The user corrected that `gh` worked normally. The durable lesson is the attribution boundary: a pre-command host negotiation failure is not evidence about `gh` or GitHub.
