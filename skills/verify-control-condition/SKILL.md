---
name: verify-control-condition
description: Use whenever you design or run any comparison with a "without X" / baseline / control / off condition — A/B tests, feature-flag comparisons, ablation studies, skill-on-vs-off benchmarks, before/after measurements. Forces you to prove the control condition is actually free of X by inspecting raw execution evidence, instead of assuming absence because you didn't put X in the prompt/config. Also covers the sibling failures that hide inside the same "trusted my own design instead of checking evidence" pattern: single-trial overconfidence, fixture answer-leakage, shared mutable state contaminating trials, mismatched instrumentation between compared conditions, and polling against a premature (not terminal) completion artifact.
---

# Verify the Control Condition

Designing a "without X" condition is a claim, not a fact. The claim is only true once you have checked — every time you build a comparison and don't check, you are trusting your own design instead of the evidence, which is exactly the failure this skill exists to catch.

## The core failure and why it's expensive

A real example: a benchmark compared an AI skill's effect by embedding its instructions directly in prompts for the "with_skill" condition, and omitting them for "without_skill" — a reasonable design, explicitly chosen to avoid relying on any harness-specific skill-loading mechanism. But the skill was *also* globally registered on the machine (symlinked into the CLI's own skill-discovery directory), so the model could — and did — discover and read the skill's file directly during "without_skill" runs, regardless of what the prompt said. This went unnoticed through a single ad-hoc test, then a 42-run benchmark, then an 84-run benchmark — hours of compute and human attention spent measuring a control condition that was never actually controlled. It was found in one command: `grep -c "skill-name" harness_log.txt` on a single run. That one grep, run once, right after the first "without_skill" execution, would have caught it before any of the expensive re-runs.

The general shape: you designed condition B to lack property X. You never checked. B silently has X anyway, through a path you didn't think to block (global config, environment inheritance, shared state, a cache, a default). Every result computed under the unverified assumption is wrong, and the cost compounds with every re-run you do before catching it.

## The rule

**Before trusting any "without X" result, grep the raw execution trace for X's own name or signature — at least once, on the first run, before scaling up to more trials or more conditions.** Not the summarized output, not your own recollection of how you configured it — the actual log of what the system under test did. If X could plausibly be discovered through more than one path (a prompt, a config file, an environment variable, a global registry, a cache directory, an auto-loaded default), check that every path is closed, not just the one you edited.

This generalizes past "skill A/B tests": any time you build a baseline/control by *subtracting* something from a full setup, the subtraction is unverified until you inspect what actually ran. Cheap ways to verify, pick whichever fits:
- Grep the raw stdout/stderr/tool-call log for the feature's name, file path, or a distinctive string from its content.
- Diff the "with" and "without" prompts/configs byte-for-byte and confirm the diff is *only* the intended feature.
- If the feature could load from a global/user-level location outside your control (a symlinked plugin dir, a `$HOME`-scoped config, an OS-level default), explicitly override that scope for the run (an isolated `$XDG_CONFIG_HOME`-style env var, a scratch home directory, a `--no-plugins`-style flag) and verify with the same grep that the override worked — overriding without verifying is the same unverified-claim mistake one layer down.

## Sibling failures — same root, different surface

These showed up in the same benchmark, and they all share the same cause: trusting the design instead of checking the evidence.

**Single-trial overconfidence.** A result from one run is a sample, not a fact. Report "unconfirmed, n=1" rather than a confident causal claim, or run enough trials to see the actual spread before concluding anything. A value that looks anomalous after one run is exactly as likely to be a fresh sample from a wide distribution as it is to be a real effect — you cannot tell which without more trials.

**Fixture answer-leakage.** When you build a test fixture meant to see whether a subject discovers something on its own, read the fixture back as if you were the subject with no prior context. A filename, comment, or variable name that spells out the intended finding (e.g. naming a corrupted test file `broken.pdf`) turns "can it find this" into "can it read a filename" — a different, much easier question that silently invalidates the test.

**Shared mutable state across trials.** If multiple runs write to the same physical location (a shared working directory, a shared cache, a shared file created by a setup step), a later run can inherit an earlier run's leftovers and skip the exact step you meant to test. Isolate each trial into its own copy/sandbox whenever the thing under test can write anything.

**Mismatched instrumentation between compared conditions.** If you measure condition A through a path that gives you raw logs and token counts, and condition B through a path that only gives you a final summary, any difference you observe might be a difference in what you *can see*, not a difference in what happened. Match the measurement method before comparing the measurements.

**Polling against a premature artifact.** When waiting for a background job, poll for the artifact that is written *last* (e.g., a final result file), not one written early in the job's lifecycle (e.g., a directory or an initial log line that exists before the expensive work even starts) — the latter reports "done" while the real work is still running, and reads as a false failure if you check the wrong thing right after.

**Verifying your fix instead of verifying the claim.** After you find and fix one real bug in the setup (say, a shared directory contaminating trials), it is tempting to define "done" as "my fix works" — run a small test, confirm the fix's own mechanism holds, and scale up. But "my fix works" is a narrower claim than "this result is now trustworthy." A cell that has already flipped between wildly different values across the day is strong evidence that *something* is wrong — not evidence that you've found *the* something. Fixing one bug and confirming that specific bug is gone does not rule out a second, independent bug producing the same symptom (in one real case, a shared-directory leak and a global skill-registration leak were two separate causes of the same instability; fixing the first and re-testing looked like success right up until the second was found by a completely different check). Before scaling up on the strength of "I fixed a bug and verified the fix," generate at least one alternative explanation for the original anomaly and check whether it's also ruled out — don't let finding one real cause end the search for others. This is the same "hypothesis lock-in" failure as thickening evidence for your current theory instead of testing a competing one; it just resurfaces one level up, in verifying your own patch rather than in diagnosing the original task.

## What to do in practice

1. State explicitly what "without X" is supposed to guarantee, in one sentence, before running anything.
2. Run one instance of the control condition. Before looking at its *result*, grep its raw execution trace for direct evidence that X was absent.
3. Only after that check passes, scale up to more trials, more conditions, or a bigger benchmark. Re-verify after any change to fixtures, sandboxing, or environment — a fix in one place can reopen the leak through another path. If the specific cell you're re-checking has flip-flopped before, treat "my fix's mechanism works" as insufficient evidence on its own; explicitly ask "what else could produce this same symptom" before trusting the number and moving on.
4. When reporting results, name the check you ran to confirm the control condition held, the same way you'd cite the command you ran to verify any other claim.
