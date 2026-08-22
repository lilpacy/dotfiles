# Agent CLI config-leak paths (Claude Code / Codex)

Measured on Claude Code 2.1.228, macOS 26.2, in an otherwise-empty cwd. Command names and flags are stable; exact skill/hook counts are this environment's snapshot, not a durable number.

## Claude Code

| Leak path | Closed by `--bare` | Closed by empty `CLAUDE_CONFIG_DIR` |
|---|---|---|
| `~/.claude/skills/` | yes | yes |
| `~/.claude/plugins/cache/*/skills/` | yes | yes |
| `settings.json` hooks (SessionStart / UserPromptSubmit) | yes | yes |
| `~/.claude/CLAUDE.md` / project `CLAUDE.md` auto-discovery | yes | no |
| `settings.json` `env` / `model` / `effortLevel` / `outputStyle` | no | yes |
| binary-embedded skills (dataviz, security-review, init, run, loop, simplify, claude-api) | yes | no |
| explicit `/skill-name` resolution | no | yes |

Neither flag alone closes every path; both are required for a true zero.

## Codex

| Leak path | Closed by replacing `CODEX_HOME` | Closed by `--ignore-user-config` |
|---|---|---|
| `$CODEX_HOME/skills/` | yes | no |
| `$CODEX_HOME/AGENTS.md` (global instructions) | yes | no, confirmed full-text injection even with the flag set |
| `$CODEX_HOME/hooks.json` | yes | no |
| `$CODEX_HOME/memories/` | yes | no |
| `$CODEX_HOME/rules/` (execpolicy) | yes | no, needs separate `--ignore-rules` |
| `config.toml` (MCP / model / profile) | yes | yes |
| project `AGENTS.md` (parent-directory search) | no | no, needs an empty cwd or container |
| 5 binary-embedded skills (imagegen, openai-docs, plugin-creator, skill-creator, skill-installer) | no | no |

`CODEX_HOME` replacement is effectively the only lever. `auth.json` lives under `CODEX_HOME` too, so copy just that file into the empty replacement directory before use. Do not add the `--ephemeral` flag: it also drops the rollout/audit log needed for the contamination-verification gate.

## Cross-product comparability

Claude Code can reach a literal zero injected skill/hook count; Codex cannot (5 embedded skills always remain). Do not compare a raw skill/hook count between the two products as if it were the same metric — compare each product's isolated-vs-default delta instead.
