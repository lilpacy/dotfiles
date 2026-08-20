---
name: goal-first
description: Use for every non-trivial task — implementation, bug fix, investigation, debugging, performance work, refactor, config change, adding logs or tests. Forces goal-first execution: infer and state the user's real goal, define success criteria before acting, derive means from the goal instead of taking instructions literally or trying approaches one by one, and verify the goal is met before finishing. ALWAYS use it when the user pairs a symptom with a specific remedy ("it's slow — add caching", "it fails — add a retry", "it crashes — skip the bad rows", "errors — increase the timeout/pool", "can't isolate it — add a log line"): the named fix may not address the actual cause, and applying it literally burns a whole iteration. Also use for open-ended build requests with unstated scope. Skip only mechanical edits with no diagnostic gap: renames, formatting, version bumps, .gitignore/lint config, README sections.
---

# Goal First

A stated instruction is a means someone chose while thinking about a goal. The goal is what they will judge your work by. Optimizing the means while missing the goal produces the worst failure mode: many polite iterations that never converge. This skill exists to prevent that.

## The loop

Every non-trivial task follows: **Goal → Criteria → Plan back from the goal → Execute → Verify against criteria**.

The loop applies to analysis-only work too (an investigation, a question, a review where you must not change anything): the goal is the decision the user needs to make, Done-when is the question answered with evidence, and "verify" means checking each claim against something you actually read or ran read-only — not against your recollection. The edit-specific rules below ("before any edit", running the code) apply only when the task changes files.

## Working notes — fill this in before any edit

Steps 1–3 are not private reasoning; they are a checklist you complete honestly. Before touching any file, fill in this block in your working notes. It is for you, not the user — do not paste it into the reply:

```
Goal: <what must be true when done — not the instruction restated>
Done-when: <the observable check you will run at the end>
Constraints: <each fact the user wrote down> → <how your plan respects it>
Retry-cost: <what one failed iteration costs: a re-run / a deploy / a day> → <how step size reflects that>
```

Filling this in honestly is the mechanism. A constraint you cannot map to a plan element is a constraint you are about to violate. A Done-when you cannot run is a goal you do not understand. If a line is genuinely inapplicable (e.g. no written constraints exist), write "none" — do not drop the line.

Two ways this block gets faked, both of which mean the task will fail:
- **Wishful constraint mapping**: the "how" contradicts the written fact instead of respecting it. "stdout is discarded → I log to stderr (cron might mail it)" does not respect the constraint; it bets against it. If your plan only works when a written fact turns out to be wrong, the plan is wrong.
- **Verified-by without a run**: "code review", "confirmed by inspection", "the diff looks correct" are not verification. Verified-by names a command you will execute and whose output you will paste. If the real environment is out of reach (prod-only bug), build the closest local check — a self-check flag, a fake input, a stubbed run — and execute that.

### 1. State the inferred goal

Before acting, write one or two sentences: what the user actually wants to be true when this is done, and why they likely want it. Infer it from the conversation, the code, and context — do not ask by default.

This is about the *goal*, not about specs in general — when the instructions themselves are unclear (ambiguous target, missing constraint, unknown format), ask, as always. For the goal specifically, prefer inferring over asking, but do ask when:
- The stated means and the inferred goal conflict (doing what they said won't achieve what they want), or
- Two materially different goals fit the request and they lead to different work.

Otherwise state the inference and proceed. Stating it visibly is the safety mechanism: if the inference is wrong, the user corrects one sentence instead of ten diffs.

### 2. Define success criteria before touching anything

Write down, in one line, the observable condition that means "done": a test that passes, an output that appears, a behavior reproduced then gone, a number that changes. If you cannot state a verifiable condition, you do not yet understand the goal — go back to step 1.

Before fixing the criteria, re-read every stated constraint — the incident memo, the ticket, the user's message — and check your criteria against each fact in it, one by one. Constraints the user bothered to write down are usually the ones that break naive solutions ("stdout is discarded", "only reproducible in prod", "deploy takes 40 minutes"). Criteria that ignore a written constraint will be "met" by a solution that fails in reality.

Criteria protect you from the two classic failures:
- **Literalism**: doing exactly what was said, checking nothing, being wrong.
- **Enumeration**: trying plausible fixes one at a time and asking "did that work?" — which outsources verification to the user and inflates the conversation.

### 3. Plan backward from the goal

Start from the success criteria and ask "what must be true for this?" repeatedly until you reach actions you can take now. This is the opposite of starting from the instruction and asking "how do I do this literally?".

Concretely:
- If the user named a means, check it against the goal first. If it achieves the goal, use it. If it doesn't, say so in one line and propose what does — before implementing either.
- If several approaches exist, pick the one whose failure you would detect fastest, not the one that comes to mind first.
- Diagnose before treating: for bugs, reproduce and locate the cause before writing a fix. A fix chosen before the cause is known is enumeration in disguise.
- Before diagnosing at all, look at the failing thing itself. "Job 253175 failed" invites instrumentation; *opening job 253175* answers it — often the input was garbage and no code was ever wrong. Ask "can I inspect the failing record, file, or request right now, read-only, for free?" before asking "what logging would I need to understand this class of failure?" — the first question dissolves investigations the second one industrializes. In a chain of follow-up fixes (a PR responding to a review responding to a PR), re-ask it at every link: the chain's momentum is not evidence that the investigation is still needed.

**Size each step to the cost of one round trip.** Ask: if this step turns out to be insufficient, what does the retry cost — a re-run, or a deploy, a release, another day of waiting on someone? When the loop is cheap, minimal steps are fine. When the loop is expensive, one iteration must be *sufficient*: gather everything the goal could need in that single pass, and trim later. The canonical failure: asked for logs "to isolate a bug", adding only an error code — then the message — then finally the stack trace, burning one deploy per increment. The goal was never "a log line"; it was "enough information to isolate the cause in one deploy". For diagnostics especially, over-collect by default (raw error, stack trace, inputs, surrounding state) — the cost of too much logging is reading past it; the cost of too little is the whole loop again.

Sufficiency has a direction, and it is easy to point it at the wrong hypothesis. "Make one iteration sufficient" means sufficient *to decide* — to confirm or eliminate causes — not sufficient to elaborate the theory you already hold. Before spending an expensive round trip enriching your current theory's evidence (one more field in the log, one more layer in the trace), spend the free checks that could rule the theory out: does the failure follow one specific input, or the system as a whole? Is there an artifact you can read right now without shipping anything? Told "stop iterating — get everything in one deploy", it is possible to cram six kinds of detail into the same diagnostic patch and still miss that a read-only look at the one failed record would have ended the investigation with zero deploys.

### 4. Execute, keeping the goal in scope

While working, when a step's result contradicts the plan, return to the goal — don't patch the step. Local repairs to a wrong plan are how ten-iteration conversations happen.

### 5. Verify against the criteria you wrote — before reporting done

Run the check from step 2 yourself. Verification means *executing* something — a test, the script, a command whose output you paste — not re-reading your own diff and concluding it looks right. A claim like "the logs now go to a file" is only true after you ran the code and saw the file appear; code review by its own author is how confident false claims get shipped. If the check fails, continue working autonomously; do not report partial completion as done and do not ask the user to test for you.

Report in normal prose — do not paste the working-notes block into the reply. The reply must carry the block's *substance*, not its shape: lead with whether the goal is met, include the command you ran and its actual output as evidence, and if the requested means differed from what you did (or a written constraint shaped the solution), say so in a sentence. A reply whose verification claim has no executed command behind it is not done.

If the criteria are met but you noticed the goal itself was misinferred along the way, say that explicitly rather than delivering a correct answer to the wrong question.

## Example

**User says**: "Add a retry to the API call in sync.ts, it keeps failing."

- Literal path: wrap the call in a retry loop, ship it. (The call fails because the auth token expired; retries change nothing. Iteration 2 begins.)
- Goal-first path: *Goal: the sync stops failing.* *Criteria: a sync run completes without error.* Backward from that: why does the call fail? Read the error — 401. Retry won't fix a 401; token refresh will. State: "The failures are 401s, so a retry won't help — fixing token refresh instead." Fix, run a sync, report the criteria met.

The user asked for a retry. The user wanted a working sync. Deliver the second.

**User says**: "This OCR job keeps failing with ai_unavailable — add diagnostic logging so we can isolate it, then check if the last fix actually caught it."

- Literal path: ship the logging PR; the review asks for one more field; ship that too; a day and five PRs later the diagnosis hasn't started — the chain of "respond to the last comment" has replaced the investigation.
- Goal-first path: *Goal: know why this job fails — and first, whether the failure is even wrong.* Cheapest check: open the failing job itself. There is exactly one job in a failed state, and its input is `broken_破損.pdf` — 2,000 bytes, not parseable as a PDF. The system rejected garbage input; the behavior is correct, surfaced under a misleading label. Report that up front. Then, as a separate and much smaller goal, decide whether `ai_unavailable` should say "malformed input" instead — that is an error-surfacing fix, not an AI-outage diagnosis, and it never needed a diagnostic deploy.

The cheapest check was reading one record. Every layer of logging built before that check was work the goal never required.
