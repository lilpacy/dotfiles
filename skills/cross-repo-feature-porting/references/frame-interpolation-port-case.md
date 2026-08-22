# Frame-Interpolation Timeline Port: Worked Case

Condensed record of a real port from a prototype repository into a product repository (multi-frame interpolation timeline). Kept for the pattern, not the specifics of this one feature.

## 1. Tick-density and pixels-per-second drift (porting regression)

Symptom reported by the user with a screenshot: after the port, the timeline felt harder to use because there were fewer tick marks to judge exact seconds by.

Root cause: while re-implementing the timeline ruler, the port had quietly coarsened the sub-tick interval and the pixel scale versus the prototype, even though the algorithmic logic (frame placement, snapping) matched.

| Zoom level | Prototype (correct) | Ported (regression) |
|---|---|---|
| >= 180 percent | sub-tick 0.1s / major 0.5s | sub-tick 0.1s / major 0.5s (matched) |
| 80-180 percent | sub-tick 0.1s / major 1s | sub-tick 0.5s / major 1s (coarsened) |
| < 80 percent | sub-tick 0.1s / major 2s | sub-tick 1s / major 2s (coarsened) |

Also: pixels-per-second was 96 in the prototype at all zoom levels, ported as 64. Restoring both values (0.1s sub-tick at every zoom band, 96 px/sec) fixed the density complaint. Neither typecheck, lint, nor the test suite caught this: the ported code was internally consistent and passed everything, it was simply tuned to different numbers than the reference.

Lesson generalized into the skill: build the constants ledger from the reference source before or during the port, not after a user complains.

## 2. WebM bitrate: pre-existing defect, not a porting regression

Symptom: the downloadable combined WebM output looked worse than the same content played back frame-by-frame in the UI.

Investigation compared two paths:

| Path | Encoding | Quality |
|---|---|---|
| In-app frame playback (slideshow) | Per-clip video, frames extracted as WebP quality 0.9 | Good |
| Downloadable combined WebM | MediaRecorder with no explicit bitrate -> browser default (about 2.5 Mbps) real-time VP9 | Poor, line art collapses |

Checking the reference implementation showed the exact same gap existed there too: MediaRecorder was constructed with only a mimeType, no videoBitsPerSecond, and an unused UI field implied a bitrate control that was never wired up. This was not something the port broke; it was already broken upstream.

Decision: fixed it as a general improvement in the target repo (added a computed videoBitsPerSecond scaled by resolution and fps, clamped to a floor and ceiling) without describing it as a porting fix, and documented that the still-image ZIP output remains the quality source of truth while the WebM is a convenience preview.

Generalized lesson: before attributing a defect to the port, reproduce the same code path in the reference. Fixing a pre-existing defect and fixing a porting regression are different diffs and should be described to the user differently.

## 3. Client-side re-encode: reload and cache semantics

Because the combined video is produced by MediaRecorder in the browser at generation-completion time, a bitrate fix only changes output for generations that happen after the fix is loaded:

| Aspect | Timing |
|---|---|
| Static help/sample pages | Fixed on next page load |
| In-app frame playback quality | Unaffected either way, already good |
| Downloadable WebM quality | Only on the next full generation, after reload |

Caveat surfaced and communicated to the user: the reload needed to load the fixed client code also clears the in-memory per-clip generation cache (no server-side persistence in this design), so a reload means every clip regenerates from scratch, not just a re-encode. Gave the user the exact reproducible inputs (which keyframes at which second offsets) so the regeneration was a one-click repeat rather than a guess.

## 4. Fencepost frame-count explanation

Symptom: user expected keyframes at frame numbers 1, 6, 26, 36 in an exported sequence but the actual output had them at 1, 7, 31, 36, which looked like a bug.

Explanation approach: rather than asserting correctness, derived the arithmetic per boundary.

| Keyframe | Placed at | Index math (12 fps) | Frame number (1-based) |
|---|---:|---|---:|
| 1 | 0.0s | 0 x 12 = index 0 | 1 |
| 2 | 0.5s | 0.5 x 12 = index 6 | 7 (not 6: index-to-1-based-count off-by-one) |
| 3 | 2.5s | 6 (end of segment 1) + 24 (segment 2 length) = index 30 | 31 (not 26: segment length is 24 frames, not 20) |
| 4 | 3.0s | 3.0 x 12 = 36, but this is the closing boundary | 36 (last frame is the closing boundary itself, not boundary+1) |

Segments are sampled as half-open intervals [start, end), so a boundary keyframe belongs to the next segment as its first frame, except the very last keyframe, which is the closing boundary of the final (closed) segment. The exported file names matched this derivation exactly, confirming the export was correct and the discrepancy was purely a counting-convention mismatch between the user expectation and the half-open-interval implementation.
