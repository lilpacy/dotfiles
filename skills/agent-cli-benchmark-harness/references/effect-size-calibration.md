# Effect-size calibration for agent skill/AGENTS.md evals

Condensed from research cited in the source vault; treat these as priors for planning trial counts, not as universal constants.

## SWE-Skills-Bench (public SWE skills, ~565 real GitHub-derived tasks, 49 skills)

| Bucket | Count | Effect |
|---|---|---|
| No measurable effect | 39 / 49 | pass rate essentially flat |
| Clear improvement | 7 / 49 | up to +30%, all narrowly specialized to one workflow |
| Regression | 3 / 49 | up to -10% |
| Population average | 49 / 49 | +1.2% |

Reading: the mechanism is not inert, the *distribution* is bimodal-ish with a long specialized-win tail and a fat no-effect middle, and a nontrivial regression tail. A skill's prior bucket correlates with specialization, not with skill-as-a-mechanism.

## Vercel Next.js 16 eval (delivery-mechanism comparison, single framework/suite)

| Knowledge delivery | Pass rate |
|---|---|
| AGENTS.md with embedded doc index (always-resident) | 100% |
| Skill with explicit usage instructions in the prompt | 79% |
| Skill, default triggering behavior only | 53% |

Reading: same underlying knowledge, three delivery mechanisms. The 53 to 79 point gap is a routing/triggering effect (explicit instruction to use it); the 79 to 100 gap is a residency effect (always in context vs. on-demand). Neither gap is a content-quality effect - don't attribute either to the skill's text being weaker.

## Planning consequences

1. A true population-average effect on the order of +1% cannot be distinguished from zero at n=3; before running a benchmark, pick the effect size you actually care about (e.g. a specialized skill might realistically hit +10-30%) and size the trial count for that, not for the population average.
2. Specialized, narrowly-scoped skills (the kind generated from your own repeated corrections and errors, as opposed to public general-purpose skills) structurally resemble the winning 7/49 bucket more than the losing 39/49 bucket - a generic skill's poor average performance in published evals does not transfer as a prediction for a skill built from your own friction.
3. When an A/B shows "no difference," default hypothesis should be insufficient power or a delivery-mechanism confound, not "skills don't work" - rule those out before concluding the content itself is ineffective.
