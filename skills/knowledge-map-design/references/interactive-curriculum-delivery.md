# Interactive curriculum delivery

Use this procedure after a purpose curriculum already exists. It turns a static sequence into a guided learning session without changing reusable domain truth.

## Start from the learner's intended stage

1. Resolve numbering ambiguity explicitly. If the curriculum starts at stage 0 and the learner says "first stage," state the assumed interpretation and make switching cheap.
2. Show only the current stage's decision rule, exercise, and passing evidence.
3. Ask one focused question per turn. Preserve progress between turns instead of restating the whole curriculum.

## Respect learner-controlled advancement

Treat an explicit request to advance, or a statement that the current capability is understood, as a pacing decision rather than another quiz opportunity.

| Remaining item | Action |
|---|---|
| Required prerequisite for the next stage | Explain the dependency in one line and ask only for the missing evidence |
| Optional property, enrichment, or interface detail | Record it as skipped and advance immediately |
| Already demonstrated by the learner or visible state | Reuse the evidence; do not ask the learner to restate or re-enter it |

Do not turn curriculum completeness into ceremony. A stage is complete when its intended decision can be made, not when every available property has been discussed.

## Gate on evidence, not answer shape

A correct category name does not prove the distinction was understood when the stage requires a rationale. Accept concise wording when it demonstrates the actual rule; do not demand ceremonial prose.

For a classification stage:

| Evidence | Result |
|---|---|
| Correct labels and required rationale | Pass |
| Correct labels without the decisive distinction | Ask one discriminating follow-up |
| Incorrect label | Explain the violated rule and retry the smallest failing case |

The follow-up should isolate the boundary between the confused concepts. Once the learner states that boundary correctly, record the stage as passed and advance.

## Turn a real goal into a measurable exercise

When the next stage uses the learner's real work:

1. Identify the weakest ambiguity first, such as an overly broad scope, a means presented as the goal, or an outcome with no measurement boundary.
2. Separate goal, means, scope, non-goals, success measure, and deadline.
3. If several workstreams are proposed, require a shared outcome before grouping them under one initiative or learning artifact.
4. Define the metric before inventing an improvement target: unit of analysis, start event, end event, aggregation, baseline period, missing-data handling, and calendar-time versus working-time semantics.
5. Prefer measured baselines over guessed percentages. Ask for the next missing fact only.

## Reconcile product semantics with live UI

When a curriculum teaches a changing software product, keep three evidence layers separate:

| Layer | What it proves | What it does not prove |
|---|---|---|
| Domain or curriculum model | The concept matters to the lesson | The current product exposes a matching control |
| Current official documentation | The product documents the capability | The learner's plan, workspace, rollout, or screen exposes it |
| Learner screenshot or inspected UI | A value or control is currently visible | The capability is absent everywhere when it is not visible |

Before making a property an exercise or giving a click path:

1. Read the visible state first; reuse values already shown instead of asking the learner to set them again.
2. Verify the control or location in the learner's UI when possible.
3. If documentation and the live screen differ, preserve the conceptual lesson but mark the UI step optional or unverified and continue.
4. Do not identify an icon from resemblance alone. If its function is unverified, describe the target information rather than asserting where to click.

## Completion record

At each turn, retain only:

- confirmed facts;
- unresolved fields;
- current stage and passing status;
- the single next question.

Do not infer mastery from exposure, silently fill missing business facts, or advance because the learner used the expected vocabulary.
