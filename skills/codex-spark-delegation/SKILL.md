---
name: codex-spark-delegation
description: "Delegate coding tasks to Codex (gpt-5.3-codex-spark) via `codex exec` while acting as PM: write work-order prompts, dispatch, verify results from the working tree, and iterate with `codex exec resume`."
---

# Codex Spark Delegation

Act as the PM: plan and review in this session, and delegate the actual
code editing to Codex's fast implementation model (`gpt-5.3-codex-spark`)
via `codex exec`. Unlike `cursor-composer-delegation` (UI automation,
fire-and-poll), `codex exec` is a synchronous CLI: it blocks until the
task finishes, returns the agent's final message on stdout, and edits the
working tree directly. No IDE, no Accessibility API, no polling.

Use `codex-exec-review` for reviews (read-only). This skill is for
implementation (writes).

## Dispatch Template

```bash
command codex exec \
  -m gpt-5.3-codex-spark \
  --sandbox workspace-write \
  -C /path/to/repo \
  -o /tmp/codex-spark-last-message.txt \
  "<work-order prompt>"
```

- `-m gpt-5.3-codex-spark` — the fast implementation model. Do NOT
  omit it; the config default is a different (slower, pricier) model.
- `--sandbox workspace-write` — real containment, verified empirically:
  under `--sandbox read-only` a file-write attempt failed with
  `Operation not permitted`, and the run header showed
  `sandbox: read-only`.
- CAVEAT: this user's shell has `alias codex='codex --yolo'`
  (`common.sh`). That alias silently overrides `--sandbox`/approval
  flags — a run through the alias showed `sandbox: danger-full-access`
  even with `--sandbox read-only` passed explicitly. Always invoke as
  `command codex exec ...` (bypasses the alias) when running this
  skill's commands from an interactive shell, and check the run
  header's `sandbox:` line to confirm the mode actually took effect.
  `trust_level` in `~/.codex/config.toml` is unrelated to sandbox
  enforcement — it only gates loading project-local `.codex/` config.
- `-C <repo>` — sets the agent's working root. Prefer this over `cd`.
- `-o <file>` — writes the final message to a file so you can re-read
  the result without scraping stdout.
- For long tasks, run via Bash with a generous `timeout` (implementation
  runs commonly take 1-10 min) or `run_in_background: true` and check
  the output file when notified.

## Prompt Rules (work order, not conversation)

- Goal, constraints, acceptance criteria. Exact file paths when known.
- "Do not commit" — commits are the PM's job (`git-commit-workflow`).
- Tell it which tests/linters must pass, and to run them itself before
  finishing (unlike review runs, execution is allowed and expected).
- State what NOT to touch (unrelated files, lockfiles, formatting-only
  churn).
- Never include secrets; prompts go to OpenAI's backend.

Example:

```bash
command codex exec -m gpt-5.3-codex-spark --sandbox workspace-write -C ~/repo \
  -o /tmp/spark-out.txt \
  "src/foo.ts の parseConfig にバリデーションを追加して。
   受け入れ条件: 不正な port で Error を throw、既存テスト npm test が全て通る。
   テストは tests/foo.test.ts に追加。実装後に npm test を自分で実行して確認して。
   コミットはしないで。無関係なファイルやフォーマットだけの変更もしないで。"
```

## Verify

`codex exec` returning is not acceptance. After it exits:

```bash
git -C /path/to/repo status --porcelain
git -C /path/to/repo diff
```

Read the diff yourself and run the project's tests/linters yourself to
accept or reject — do not trust the agent's claim that tests passed.
Then commit via `git-commit-workflow`.

## Fix Loop (resume)

The run header prints `session id: <UUID>` — capture it from stdout.
If the result is wrong, resume the same session so context is retained:

```bash
command codex exec resume <SESSION_ID> \
  "npm test が X で落ちる。エラー: <paste>. Z には触らずに修正して。"
```

Cap the loop at ~3 rounds; if it still fails, take over in this session
or re-plan. To discard a rejected attempt before retrying from scratch,
capture the baseline BEFORE dispatch (`git stash` the user's dirty
state, or note the pre-dispatch `git status --porcelain`), then revert
only the files the agent touched: `git -C <repo> checkout -- <files>`
and delete its new files individually. Never bulk `git clean -fd` — it
destroys the user's untracked files too.

## Parallel Tasks

One repo checkout = one task at a time (both agents write the same
tree). For parallel delegation, give each `codex exec` its own git
worktree via `-C`. Never switch branches in a tree while a run is in
flight.

## Failure Semantics (same as codex-exec-review)

- Startup MCP transport errors (`rmcp::transport::worker ... http://127.0.0.1:...`)
  are noise from unreachable local MCP servers. If a final `codex`
  answer arrives, the run succeeded (degraded); report the sidecar
  failure separately.
- Treat a run as failed only when `codex exec` exits without a final
  answer. Then try `command codex exec resume <SESSION_ID>` once
  before rerunning from scratch.
- Do not report "implementation done" unless the final answer was
  obtained AND you verified the diff/tests yourself.

## When to Use Which Delegate

- `codex-spark-delegation` (this): synchronous and scriptable; best
  default for well-specified implementation tasks. Sandbox is real
  containment as long as it's invoked via `command codex` (see caveat
  above) — but still verify the diff yourself, same as any delegate.
- `cursor-composer-delegation`: when the user wants work visible in the
  Cursor IDE, or wants to keep working while tasks run fire-and-forget.
- Claude subagents (Agent tool): when the task needs this session's
  conversation context or tight mid-task steering.
