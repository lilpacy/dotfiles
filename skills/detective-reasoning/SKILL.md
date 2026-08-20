---
name: detective-reasoning
description: Use when investigating anything with a *history* of inconsistent observations — a result that flips between runs, a bug that appears and disappears, benchmark numbers that contradict yesterday's, a "why did X change" question about something already explained once. Also use at the exact moment you notice you've explained the newest anomaly and feel done: that feeling is the trigger. Forces keeping every anomaly from the whole timeline on one evidence board, replaying each new theory against all of them, holding multiple simultaneous causes, treating the measuring instrument as a suspect, and deliberately hunting disconfirming evidence. Escalate here from `verify-control-condition` when individual checks keep passing but the overall picture still doesn't cohere.
---

# Detective Reasoning

Finding *an* explanation is not finding *the* explanation. The pull to close the case at the first fact that fits the newest anomaly is exactly the pull this skill exists to resist.

## A solved case, for calibration

One benchmark cell — one model, control arm — produced these observations across a single day:

1. Morning, one ad-hoc run: catastrophic failure.
2. Midday, three trials: perfect scores.
3. Afternoon: a real bug found — trials shared a writable fixture, so later runs inherited earlier runs' side effects. Fixed, re-verified, declared solved; an 84-run benchmark launched on the strength of it.
4. Evening: a prompted grep of raw logs caught the control arm reading a globally-registered skill file — a second, independent real bug. Environment isolated. Declared solved again.
5. After isolation: the same grep *still* hit 5–17 times per run. A third leak path?

The full answer needed four elements, every one necessary:

- **Two independent real causes** — the shared fixture and the global skill registration — active at the same time, producing the same symptom.
- **One probabilistic mechanism** — a model that *can* see a skill only *sometimes* chooses to read it. This is the only way to reconcile observation 1 with observation 2: the contamination was equally available during the catastrophic morning run and the perfect midday runs.
- **One lying witness** — the post-isolation grep hits were the results directory's own name and the benchmark repo's git history matching the search string. The isolation had worked; the detector hadn't.

At steps 3, 4, and 5 the investigation held a theory that explained the newest observation while contradicting an older one, and each time it shipped anyway. The case closed only when all five observations were finally read as one dataset.

## The rules

**1. One board.** List every anomaly of the whole investigation, in order, including the ones you believe you've already explained. A new theory is tested against the board, not against the observation that prompted it. "Explains #5 but contradicts #1" is not a solution — it's a clue that a variable is missing.

**2. Suspects are not mutually exclusive.** One confirmed cause doesn't acquit the others. Two independent bugs producing the same symptom is not exotic — it happened here within one afternoon. Before closing, ask: if a second cause were also active, what would that look like, and is that signature anywhere on the board?

**3. Interrogate the instrument.** Every observation on the board was produced by some measurement — a grep, a test, a log, a score. When an observation resists every theory, check whether it is real before inventing mechanisms for it: read the raw matches instead of the count, ask what the instrument would report on a known-clean and a known-dirty sample, ask whether its signature collides with your own infrastructure. In this case the one unexplainable anomaly *was* the instrument. The witness lied.

**4. Probabilistic mechanisms are admissible.** "The resource was available all day but only some runs used it" does not mean the odd runs were noise — it means the mechanism has a random or conditional step. When no deterministic story fits every observation, add a variable (a probability, a trigger condition, an interaction) rather than deleting an observation.

**5. Hunt disconfirmation on purpose.** Once a theory starts feeling right, spend one deliberate pass looking for the observation that would break it — not for more that support it. A theory tested only by its friends has not been tested.

**6. Close honestly.** The case is closed when every board entry is accounted for — by a cause, a mechanism, or a demonstrated instrument fault. Anything short of that, report as "this explains everything except X; X is open." A tidy story that quietly drops one data point is how this entire day happened.

## Relation to single-claim verification

`verify-control-condition` is one claim, one check, pass or fail — run it every time you build a baseline. Detective reasoning is for when several such checks have individually passed and the totality still doesn't make sense: the same test case keeps surprising you, a fix's own verification succeeded but the number flipped again, someone asks "why did this change" about something you had quietly moved past. The unit of analysis stops being the latest check and becomes the entire timeline.
