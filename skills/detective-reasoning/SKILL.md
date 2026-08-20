---
name: detective-reasoning
description: Use when investigating unexplained or inconsistent behavior — a result that changed for no clear reason, a bug that only shows up sometimes, benchmark numbers that swing between runs, "why did X get better/worse" questions, or any situation where you've already found one plausible cause but something still doesn't add up. Forces holding every anomaly observed so far on one evidence board instead of resolving each one in isolation, testing whether a new explanation accounts for ALL of them (not just the one that prompted the search), and actively hunting for facts that contradict your leading theory instead of just the ones that confirm it. Escalate to this from `verify-control-condition` when a single verification check isn't enough — when you have a *history* of conflicting or unstable observations, not just one unverified claim.
---

# Detective Reasoning

Finding *an* explanation is not the same as finding *the* explanation. The moment you're satisfied because a new fact fits the anomaly in front of you, stop and ask what else in the timeline that explanation has to account for — and whether it does.

## Why "found a cause" isn't "found the cause"

A benchmark result for one specific test case flipped between wildly different values across a single day: catastrophic failure in an early ad-hoc test, near-perfect in a mid-day 3-trial run, still near-perfect after finding and fixing one contamination path, and *still* showing traces of the same contamination after supposedly isolating that path. Each time a new anomaly appeared, the investigation found *a* plausible cause, fixed it, ran one check that confirmed the fix worked, and moved on — treating the mystery as closed.

It wasn't closed. The theory found at each step explained the *most recent* anomaly but contradicted an earlier one: if the contamination source was globally reachable the whole time (as it turned out to be, from more than one leak path), the very first ad-hoc test should have shown the same contamination too — but it didn't. A theory that explains your latest data point while contradicting an earlier one isn't the answer; it's a partial answer sharing the stage with at least one more variable you haven't found yet. (Here, the missing variable was that the model's decision to actually *read* an available skill turned out to be probabilistic, not automatic — which is what reconciles why the same globally-reachable resource was used in some runs and ignored in others.)

This is the gap between "verify the claim you're about to act on" — one check, one moment — and detective reasoning: a discipline for when you have *a history* of inconsistent observations and are tempted to declare the mystery solved at the first fact that fits.

## The rule

**Keep every anomaly you've observed on one board, and don't retire an item just because your current lead explains the newest one.** When you find a new candidate explanation:

1. **Replay it against the whole timeline, not just the trigger.** List every strange result you've seen, in order, including the ones you thought you'd already explained. Ask whether the new theory predicts *all* of them — including the earliest one, including the ones that seemed unrelated at the time.
2. **Look for the fact that doesn't fit — on purpose.** After finding a theory that feels satisfying, spend one deliberate pass hunting for a *disconfirming* fact, not more confirming ones. The theory that survives an active search for counter-evidence is worth trusting; the theory you only ever tested by looking for support is not.
3. **Hold more than one suspect at a time.** A confirmed cause doesn't rule out a second, independent cause producing the same symptom. Before closing the case, ask "if this weren't the (only) answer, what would that look like?" and check whether that alternate signature is present anywhere in the evidence.
4. **When a fact contradicts your leading theory, don't discard the fact — upgrade the theory.** A theory that can't be made deterministic (e.g. "the resource is always available" doesn't predict "sometimes it's used, sometimes not") often means the real mechanism is probabilistic or compound, not that the contradicting data point was noise. Reach for a model with an extra variable (a probability, a second cause, an interaction) before reaching for "ignore that outlier."
5. **State what's still unexplained.** If, after all this, some part of the timeline still doesn't fit, say so explicitly rather than presenting the tidiest available theory as settled. "This explains most of what we saw; X is still open" is a more honest and more useful report than a complete-sounding story that quietly ignores one inconvenient data point.

## How this differs from verifying a single claim

Checking whether a "without X" condition is really without X, or whether a fix you just wrote actually works, is a single verification: one claim, one check, pass or fail. Detective reasoning is for when you already have several such moments scattered across a longer investigation and they don't cohere — when the honest move isn't "run one more check" but "look at everything collected so far as one connected dataset and ask what theory survives contact with all of it." Reach for it when a pattern recurs (the same test case keeps surprising you), when a fix's own verification succeeds but the broader mystery still feels unresolved, or when someone asks "why did this change" about something you'd already quietly moved past.
