---
name: cross-repo-feature-porting
description: Port an algorithm, UI, or workflow from a reference or prototype repository into a target product repository while preserving the target product visual taste and the source implementation exact behavioral fidelity. Use when asked to port, backport, or migrate an update from another repo or branch, especially when the request pairs new capability with keeping the current look and feel unchanged.
---

# Cross-Repo Feature Porting

Two independent fidelity requirements pull in different directions when porting a feature from a reference or prototype repo into a product repo: the ported feature quantitative behavior must match the reference implementation exactly, while the visual taste (colors, tone, shapes, surrounding chrome) must match the destination product, not the reference. Treat these as two separate checklists; satisfying one does not imply the other, and a request that says bring in the new algorithm or UI but do not change our current look is explicitly asking for both at once.

## Before porting

1. Read the full reference implementation end-to-end for the feature being ported (UI to state to processing to output), the same as tracing any unfamiliar system. Do not port from a summary or from memory of how this kind of feature usually works.
2. Enumerate the destination product existing visual grammar for the page being touched. See the established-product-ui-integration skill for that half of the job (matching neighboring pages surfaces, states, and interactions).
3. Build a constants ledger: every reference-owned numeric or behavioral constant that affects UX, such as tick or grid density, pixels-per-unit scale, encoding bitrate, thresholds, default ratios, timing windows, retry backoff, together with its exact reference value. These are exactly the values that porting from memory silently rounds off or cleans up, and none of them are caught by typecheck or lint or tests: the code still compiles and runs correctly, only a human looking at the rendered result (or a user screenshot) catches the drift.

## While implementing

- Port algorithmic logic and its structural constants together, in the same pass, read directly from the reference source file, not reconstructed from a description of the concept. Copy the value first, then explain why it is that value, never the other order.
- Do not silently improve a source constant while porting (coarsen a tick interval, round a size, simplify a formula) even when it looks like an easy cleanup opportunity. That is an unrequested behavior change smuggled into a port. If a reference value genuinely looks wrong, say so and ask, or flag it explicitly in the summary; do not quietly change it.
- If a defect surfaces during or after porting, check whether it already exists in the reference implementation before treating it as a porting regression: reproduce it against the same code path in the reference repo. A pre-existing defect and a porting regression require different diffs (fix at the source design versus restore parity); only attribute a defect to the port once the reference is confirmed not to have it.

## After porting: verify parity explicitly

Do not declare a port complete because the algorithm matches and tests, typecheck, and lint are green; those checks do not see UX-affecting constants. Walk the constants ledger and produce a table:

| Constant | Reference value | Ported value | Match |
|---|---|---|---|

Any mismatch is a regression to fix before calling the task done, even if the ported code still technically works. A user report phrased like this got harder to use or there are fewer marks or options now after a port is very often exactly this class of silent constant drift; go back to the ledger for the specific area the user named rather than re-reviewing the whole feature.

## Client-side generation or caching gotcha

When the ported feature does its processing or encoding in the browser rather than on the server, two consequences are easy to miss:

- A fix to client-side encoding parameters (bitrate, format, sampling rate) only takes effect on the next generation run; it cannot repair output already produced. State this explicitly; do not let the user assume a page reload fixes already-downloaded files.
- Any generation-run cache held only in browser memory (not persisted server-side) is wiped by the reload needed to load the fixed code. Say plainly that reloading means redoing the generation from scratch, and hand the user the exact inputs and parameters to reproduce it quickly if a documented sample or preset exists.

## When explaining counting or index discrepancies

If a user reports a number that looks off (a frame count, a position index, an off-by-a-few report) after a port, check for a fencepost error before assuming a logic bug: half-open interval boundaries, zero- versus one-based indexing, and the last element following a different rule than the general case are the usual causes. Show the actual arithmetic per boundary in a small table rather than asserting correctness; the derivation is the proof, and it usually reveals the discrepancy is a counting-convention mismatch, not a defect.

## Reference

See references/frame-interpolation-port-case.md for a fully worked example: tick-density and pixels-per-second drift caught from a user screenshot, WebM-bitrate pre-existing-versus-regression triage, cache and reload semantics after a client-side encoding fix, and a fencepost frame-count explanation.
