---
name: agent-cli-benchmark-harness
description: Use when designing or running a benchmark/eval harness that compares CLI coding agents (Claude Code, Codex, etc.) under different conditions — skill on/off, AGENTS.md vs Skill, prompt/model variants. Covers achieving and verifying a truly hermetic execution environment (no inherited skills/hooks/config leaking into the "without X" arm, including skills you create mid-benchmark), pinning explicit model/effort on every subagent call, parallelizing once trials are isolated, borrowed benchmark-control patterns (NOP/Oracle/Cheat/Artifact-whitelist), fixture design that doesn't leak the answer, and realistic effect-size expectations so a null result isn't mistaken for "skills don't work."
---

# Agent CLI Benchmark Harness

Building a fair "with X / without X" comparison for Claude Code or Codex is
mostly a fight against implicit inheritance, not against the model. Every
finding below was reached by actually running commands and inspecting raw
output — not by asking the model to describe its own configuration.

## 0. Decide which of two things you're actually measuring

These are different experiments and get contaminated by different things.
Don't run one experiment and draw conclusions about the other.

| Question | What varies | What must be controlled |
|---|---|---|
| Is the skill's **content** good? | skill body text | routing/trigger mechanism — bypass it entirely (§2) |
| Does the skill's **description** trigger correctly? | task phrasing | skill content itself; use should-trigger / should-not-trigger pairs |

## 1. Get a genuinely hermetic run

An unverified "clean" environment is a claim, not a fact — inspect what
actually loaded before trusting any run.

**Claude Code.** `--bare` alone is not enough: it drops hooks, LSP, plugin
sync, auto-memory, and `CLAUDE.md` auto-discovery, but a real skill directory
on disk is still resolvable via `/skill-name`, and Claude Code's handful of
binary-embedded skills (`dataviz`, `security-review`, `init`, `run`, `loop`,
`simplify`, `claude-api`, ...) survive an empty config dir alone. You need
**both** `--bare` **and** an empty `CLAUDE_CONFIG_DIR`:

```bash
docker run --rm -e CLAUDE_CONFIG_DIR=/cfg -e ANTHROPIC_API_KEY -v "$TASK_DIR:/task:ro" -w /work bench-image claude --bare -p "$PROMPT" --model "$MODEL" --effort "$EFFORT" --system-prompt-file /task/system.md
```
The skill-present arm adds only `--plugin-dir /skills/target` to the exact
same command — both arms must use `--bare`, or the harness difference itself
becomes a confound.

**Codex.** There is no `--bare` equivalent. `--ignore-user-config` only skips
`config.toml`; `AGENTS.md`, `hooks.json`, `$CODEX_HOME/skills/`,
`$CODEX_HOME/rules/`, and `$CODEX_HOME/memories/` all still load (confirmed:
a full `AGENTS.md` with 30+ lines of skill-usage rules was injected even with
`--ignore-user-config` set). The only real lever is pointing `CODEX_HOME` at
an empty directory containing nothing but a copied `auth.json`:

```bash
mkdir -p /bench/cfg_codex && cp ~/.codex/auth.json /bench/cfg_codex/
docker run --rm -e CODEX_HOME=/cfg -v /bench/cfg_codex:/cfg -v "$TASK_DIR:/task:ro" -w /work bench-image command codex exec --sandbox read-only --skip-git-repo-check --ignore-rules --strict-config -c model_reasoning_effort="$EFFORT" -m "$MODEL" "$PROMPT"
```
Codex ships 5 embedded skills (imagegen/openai-docs/plugin-creator/
skill-creator/skill-installer) that cannot be removed by any flag — Claude
Code can reach a true zero, Codex cannot, so don't compare raw skill counts
across the two products as if they were the same metric.

Full path-by-path leak table (what `--bare`/empty-config-dir/`--ignore-user-config` each do and don't close) is in `references/agent-cli-isolation-paths.md`.

**Never trust the model's self-report of what loaded.** Asking "how many
skills do you see" as a bare count produced confabulated numbers (38, 3) when
the ground truth — obtained by asking it to enumerate literal skill names —
was 0 / `NONE`. Make the preflight check a string-exact match against a known
expected set, not a number and not a yes/no self-assessment:

```bash
observed=$(docker run ... claude --bare -p 'List the exact names of every skill in your available-skills listing, one per line. If the listing is absent or empty, reply exactly: NONE')
test "$observed" = "$EXPECTED" || echo "CONTAMINATED: $observed"
```
Run this once per condition before scaling to more trials, and store
`observed` alongside the result so a contaminated run can be found
retroactively. Codex has no equivalent honest self-report gate (asked
directly to quote its injected instructions, it refused) — grep the session's
raw rollout/log JSONL for the skill's own name instead of asking the model.

**Shell alias trap.** If `~/dotfiles` or similar defines an alias that
silently adds a permissive flag to `codex`, an explicit `--sandbox read-only`
passed through that alias can be overridden without any warning (verified: a
run header showed a fully permissive sandbox despite `--sandbox read-only`
on the command line). Always invoke as `command codex ...` in a harness, and
confirm the run header's actual `sandbox:` line rather than trusting the flag
you typed.

**The skill you're building *right now* leaks into your own benchmark.**
`skill-creator`-style workflows install/symlink a new skill globally
(`~/.claude/skills/<name>`, `~/.codex/skills/<name>`) as a normal side effect
of "finish and enable this skill" — including one you drafted minutes ago
inside the very session running the benchmark. That global registration
contaminates every `without_skill` arm from that point on, for *every*
benchmark in flight, not just the one that prompted its creation (confirmed:
`grep -io "<skill-name>" harness_log.txt` found 15-17 hits per
supposedly-skill-less trial, and the transcript contained the model's own
line "非自明な調査なので<skill-name>も適用します"). This was caught only
because the user asked directly ("このスキルもう見えてるんじゃないの？") —
add a self-check for it: after creating or editing any skill mid-session,
re-run the honest-enumeration preflight above and also
`grep -rli "<new-skill-name>"` over every `without_skill` output before
trusting a comparison that started before the skill existed. Treat
`CODEX_HOME` isolation (for codex) and `--disable-slash-commands` (for
claude) as partial mitigations, not proof of closure — verify the grep is
clean on the *current* run, don't assume last run's fix generalizes.

## 2. Measuring skill *content* quality? Don't go through the Skill tool at all

If the question is "is this skill's text good," using `/skill-name` or
auto-routing to load it introduces a second variable (whether the router
fired) you didn't intend to test. Inject the content deterministically
instead:

```bash
claude --bare --append-system-prompt "$(cat skill_body.md)" -p "$PROMPT"
```
`--append-system-prompt-file` **does not exist** — it appears plausible next
to `--append-system-prompt` but is rejected at runtime; always pass the
content as an inline "$(cat ...)" string argument, not a -file flag.

## 3. Borrow real benchmark-control patterns, don't invent ad hoc ones

From Harbor (Terminal-Bench 2.0 harness) and Frontier-Bench:

| Pattern | What it catches |
|---|---|
| **NOP Run** | Skill-less arm scoring well anyway means contamination, not "the task was easy" |
| **Oracle Run** | Skill-ful arm *not* scoring as expected means the gate/harness itself is broken, check that first |
| **Cheat Trials** | Grader/assertions written to match the skill's expected behavior, so you measure "skill compliance" instead of genuine task competence |
| **Artifact Whitelist** | Only pass the grader the specific artifacts it needs to score — never let the grading step see the skill file itself |
| **Separate Verifier** | Never colocate the grader with the skill under test; a grader that can read the skill it's grading against is a leak, not a control |

**Fixtures must not leak the answer, and must not carry state across trials.**
A filename or field that hints at the intended finding (a fixture literally
named `broken_<answer>.pdf`, or a numeric field like `pdfSizeBytes` sized to
telegraph "this file is corrupt") lets the model pattern-match the filename
instead of actually investigating — inflates every arm's score and erases
the with/without gap. Use neutral names and require the model to derive the
finding from behavior/content, not metadata. Separately, if trials share a
mutable fixture directory (e.g. a `staging.db` that earlier trials wrote to),
later trials inherit earlier trials' leftover state and the task's real
difficulty becomes execution-order-dependent — give every trial its own copy
(`cp -r fixture/ trial-N/_fixture/`) rather than pointing every trial at one
shared path.

## 4. Calibrate expectations before concluding "no effect"

Published skill evals show effect sizes are small on average with high
variance, not uniformly near-zero — see
`references/effect-size-calibration.md` for the numbers. Two consequences:
detecting a true few-percent average effect needs far more than `n=3` trials
(compute required sample size for your expected effect size *before*
concluding "no difference"), and delivery mechanism (always-resident vs.
must-be-triggered vs. explicit-usage-instructions) is a separate variable from
content quality — don't attribute a routing/delivery gap to the content being
bad, and don't assume a generic/public skill's poor showing predicts anything
about a skill built specifically for your own repeated corrections and
failures (those are structurally the specialized, high-variance-upside kind).
