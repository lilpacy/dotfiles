---
name: verify-control-condition
description: Use whenever you design or run any comparison with a baseline / control / "without X" / off arm — A/B tests, skill-on-vs-off benchmarks, ablation studies, feature-flag comparisons, before/after measurements — and also whenever you write a check meant to detect contamination or absence (a grep gate, a leak detector, an isolation test). Forces two proofs instead of zero: prove the control arm is actually free of X by inspecting raw execution evidence, and prove the detector itself works by showing it fires on a known-dirty sample and stays quiet on a known-clean one. Also covers the sibling failures in the same family: single-trial overconfidence, fixture answer-leakage, shared mutable state across trials, mismatched instrumentation between arms, polling a premature completion artifact, and verifying your fix instead of the claim.
---

# Verify the Control Condition

A control condition is a claim about the world — "this arm ran without X" — and it stays an unverified claim until you have looked at raw execution evidence. Every result computed on top of an unverified control inherits its uncertainty, and the cost compounds with every run you add before checking.

## The incident this comes from

A benchmark measured an AI skill's effect by embedding its text into the prompt for the "with_skill" arm and omitting it for "without_skill". The design was fine. The machine was not: the same skill was also symlinked into the CLI's global skill-discovery directory, so in "without_skill" runs the model could — and sometimes did — find and read the skill file on its own, announcing "this is a non-trivial investigation, so I'll apply the skill too." Nothing in the prompt caused this, and nothing in the prompt could have prevented it.

The contamination survived one ad-hoc test, a 42-run benchmark, and an 84-run benchmark. It was found in seconds, by one command run against a single control-arm log:

    grep -c "skill-name" harness_log.txt

That command could have run right after the very first control run. Everything between that moment and its actual discovery was compute and attention spent measuring a control that was never controlled.

## The rule

Before trusting any control-arm result, inspect the raw execution trace of one control run for X's own signature — its name, its file path, a distinctive phrase from its content. Do this on the first run, before adding trials, arms, or models.

"Raw" matters. Inspect the actual record of what the system did — tool calls, files opened, commands executed — not the final answer, not a summary, and never the system's own report of what it saw: models asked to count their visible skills returned different numbers under identical conditions. If the invocation path gives you no raw trace at all (some subagent mechanisms don't), that is itself the finding — switch to a path that does, because a control you cannot inspect is a control you cannot claim.

Then enumerate discovery paths. Removing X from the prompt closes one path; X can still arrive through a global registry, an environment variable, a user-level config, a cache, an auto-loaded directory, a default. Close each path explicitly (an isolated home directory, a `--no-plugins`-style flag, a scratch config dir) and verify each closure with the same trace inspection. An override you didn't verify is the original mistake, one layer down.

## Calibrate the detector before believing it

The check is a measurement instrument, and instruments fail in both directions.

**False dirty.** After the global-registry leak above was fixed with an isolated home directory, the same grep still returned 5–17 hits per run — which read as "a second, unknown leak path" and nearly launched another day of hunting. Reading the actual matches dissolved them: the results directory was itself named `results/<skill-name>-<timestamp>/…`, so every quoted file path matched, and the fixture lived inside the benchmark's own git repository, so the model's routine `git log` printed a commit titled "add <skill-name> suite". The isolation had worked all along; the detector's signature collided with the harness's own naming and history.

**False clean.** The mirror failure is quieter and worse: a grep against the wrong file, a mistyped pattern, a log that was never written — all return zero, and zero reads as "verified clean".

So calibrate the gate before letting it certify anything: show it turns red on a sample you know is dirty (a pre-fix run, or a deliberately contaminated environment) and green on one you know is clean. A gate you have never seen fail detects nothing — you just haven't noticed yet. And keep the signature from colliding with your own infrastructure: don't name run directories, suites, or commits after the exact string you will grep for, and don't nest fixtures inside a repository whose history mentions X.

## Sibling failures — same root, different surface

All of these appeared in the same benchmark, and all are one mistake: trusting the design where evidence was available.

- **Single-trial overconfidence.** One run is a sample from a distribution you haven't seen. An anomalous n=1 result is exactly as consistent with "wide variance" as with "real effect" — report it as unconfirmed, or run enough trials to see the spread.
- **Fixture answer-leakage.** Re-read fixtures as the subject would, with no prior context. A corrupted test file named `broken.pdf` turns "can it discover the corruption" into "can it read a filename" — a different and much easier test that silently invalidates the result.
- **Shared mutable state across trials.** If runs share a writable directory, later runs inherit earlier runs' side effects — a database one run created lets the next run skip the exact step being tested. Give each trial its own copy or sandbox whenever the subject can write anything.
- **Mismatched instrumentation between arms.** Measuring arm A through a path with raw logs and arm B through one with only summaries makes differences in *visibility* look like differences in *behavior*. Match the measurement channel before comparing measurements. This includes the invocation itself: a shell alias that silently appends flags (`alias codex='codex --yolo'`) means the command you think you benchmarked is not the one that ran — invoke the binary explicitly (`command codex`) and check the run header.
- **Polling a premature artifact.** Wait on the artifact written last (the final result file, process exit), not one created before the expensive work starts (an output directory, an early log line). The premature artifact reports "done" mid-flight and turns a running job into a false failure.
- **Verifying your fix instead of the claim.** After fixing one real bug in the setup, "my fix works" is the wrong success criterion — the claim needing verification is "this result is now trustworthy". A cell that has already produced contradictory values is evidence that *something* is wrong, not that you found the only something: here, two independent contaminations produced the same symptom, and confirming the first fix said nothing about the second cause. Ask "what else could produce this symptom" before scaling up. When anomalies accumulate across a timeline and stop cohering, escalate from this skill to `detective-reasoning`.

## In practice

1. Write down, in one sentence, what the control arm is supposed to guarantee.
2. Run one control instance. Inspect its raw trace for X's signature before looking at its score.
3. Calibrate the gate: known-dirty goes red, known-clean goes green, and the signature doesn't match your own paths, names, or history.
4. Only then scale up. Re-verify after any change to fixtures, environment, or isolation — a fix in one place can reopen a path in another.
5. When reporting results, name the check that certified the control, exactly as you would cite the command that verified any other claim.
