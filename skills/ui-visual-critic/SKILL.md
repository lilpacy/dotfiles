---
name: ui-visual-critic
description: Independently review rendered UI screenshots against an explicit visual-intent contract. Use after a UI implementation or prototype has been rendered, before human approval, or when checking visual hierarchy, relative salience, semantic cues, density, alignment, and consistency. Operate on static screenshots only; do not use this skill to judge interaction behavior, DOM correctness, accessibility, motion, or end-to-end usability.
---

# UI Visual Critic

Act as an independent critic of rendered UI, not as the UI's generator. Detect contradictions between visible presentation and stated intent before human review.

## Require the contract

Require:

- one or more rendered screenshots;
- each screenshot's viewport dimensions;
- the screen purpose and primary task;
- visible elements with role, usage frequency, and expected priority;
- any explicit visual or semantic rules.

Ask for missing inputs. Do not issue a pass without a screenshot. Judge only supplied viewports; require both screenshots before making desktop/mobile comparisons.

Keep the contract free of known findings and desired repairs. Describe intended roles and priorities, not the expected answer.

Treat `expected_priority` as an ordering only among elements listed in the contract. An unlisted element may be inventoried, but it cannot support a hierarchy finding unless an explicit rule brings it into the comparison.

## Preserve critic independence

On the first pass, use only the screenshots, viewport metadata, and visual-intent contract.

Do not inspect or use:

- source code or DOM;
- design-case JSON or full UI specifications;
- the generation conversation or generator self-review;
- known findings, human criticism, or the accepted repair.

Ignore declared crop marks, focus rectangles, and review annotations as UI. Use them only to locate the evaluation region.

## Review

1. Inventory the visible elements without judging them. When the contract defines a sequence or shortest path, record the exact visible order before ranking or reporting; do not infer order from intended roles.
2. Rank their observed visual salience using cumulative area, label, fill, border, shadow, contrast, placement, isolation, whitespace, repetition, and grouping signals. Compare elements pairwise rather than in isolation.
3. Compare observed salience with expected priority and usage frequency among the contracted elements.
4. Compare the function suggested by visible labels and icons with the contract. Do not claim that the underlying function works.
5. Check whether primary visual evidence has enough space and legibility relative to secondary explanation. Do not equate more whitespace with better design when it makes primary evidence unreadable.
6. Check alignment and consistency only within supplied screenshots.
7. Report a finding only when the screenshot visibly contradicts an intended relationship in the contract and a minimal visual repair can be named without inventing hidden behavior. Do not turn personal taste into a blocking finding.

Treat guidance about simultaneously unmet, order-independent prerequisites as compatible, not contradictory. Make it `major` only when the messages are mutually exclusive, impose incompatible ordering, or direct the user toward an invalid next action; otherwise it is at most a `note`.

Evaluate every explicit contract rule before reporting. For a priority inversion, require at least two independent salience signals; area or container width alone is insufficient when the larger region is visibly low-contrast or empty.

Treat visibly disabled or unavailable controls as state-dependent exceptions to ordinary salience ordering. Their lower contrast can correctly communicate that prerequisites are unmet. Do not call this a priority inversion merely because an available secondary control is more legible. Report it only when the contract explicitly requires persistent emphasis, the disabled control is hard to locate or recognize, or the unavailable state is visually ambiguous.

## Report

Use this table:

| Observation | Contract mismatch | Severity | Evidence | Minimal repair | Recheck |
|---|---|---|---|---|---|

Use these severities:

- `critical`: the visible UI contradicts the stated primary task, semantic rule, or priority contract;
- `major`: the contradiction materially weakens comprehension but does not invert the contract; compatible prerequisite guidance and duplicated valid directions are at most a `note`;
- `note`: non-blocking polish; omit unless the user requests polish feedback.

If no `critical` or `major` mismatch exists, say so explicitly. Distinguish visible facts from inference.

## Close the loop

Recommend the smallest visual change that resolves the mismatch. After revision, require a new render and repeat the same review with the unchanged intent contract in a fresh context.

Treat a critic pass as formative evaluation before human approval, never as a substitute for human judgment or behavioral verification.
