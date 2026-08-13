# Runner capacity experiments

Use this procedure when someone proposes doubling CPU or memory to speed up a workflow.

## 1. Locate the only capacity change that can move wall time

For each comparable completed run, calculate:

`workflow wall time ≈ fixed orchestration + max(required job paths) + final gate`

Identify the repeated critical-path job. Do not scale every runner when one job consistently determines completion. A faster non-critical job has no workflow benefit until it becomes the critical path.

## 2. Bound the best possible result

Split the critical job into observed serial step durations. Mark steps likely to benefit from the proposed resource and leave checkout, cache transfer, network waits, artifact upload, and fixed orchestration unchanged unless measurements show otherwise.

For a proposed speedup factor `s`:

`candidate duration floor = fixed duration + scalable duration / s`

`workflow benefit ceiling = current critical path - max(candidate duration floor, next-longest required path)`

Present this as a ceiling, not a prediction. Real scaling is lower because CPU parallelism, memory pressure, I/O, and tool internals vary.

## 3. Run a matched A/B

1. Change capacity only for the repeated critical-path job.
2. Hold application SHA, workflow source, cache policy, event type, job inputs, and region constant where possible.
3. Compare at least three completed A and three completed B runs when run-to-run variance is material. Prefer exact-SHA reruns.
4. Record workflow wall time, target-job time, target-step times, next-longest path, queue time, and cost per run.
5. Report medians and ranges. Keep cold-cache and warm-cache cohorts separate.

If exact matching is impossible, name every differing boundary and classify the result as directional rather than causal.

## 4. Decide

Keep the larger runner only when the observed wall-time or reliability gain clears the agreed cost threshold. Stop scaling that job when another required path becomes critical; optimize or measure that path next.

Do not infer whole-workflow improvement from a faster isolated step, and do not promise a 2× workflow gain from a 2× vCPU label.
