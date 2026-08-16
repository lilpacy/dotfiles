---
name: omi-insight-audit
description: Use when deriving actionable insights from Omi memories, conversations, transcripts, daily summaries, people, goals, or action items, especially when claims depend on dates, speakers, task ownership, conversation boundaries, or extracted metadata.
---

# Omi Insight Audit

## Principle

Treat Omi's derived records as leads. Verify consequential claims against transcript segments and preserve the distinction between observation and inference.

## Workflow

1. Start with `get_user_profile`, then inventory the relevant datasets with counts and date ranges. Do not infer absence when screen/audio capture may have stopped.
2. Convert every timestamp to the user's timezone before interpreting relative dates such as “today” or “tomorrow”. State the timezone in the result.
3. Separate three layers:
   - raw transcript segments;
   - structured summaries, memories, people, and action candidates;
   - persisted goals and action items.
4. For important claims, resolve the referenced conversation and source segments. Normalize a leading `segment:` only for lookup; report unresolved IDs instead of inventing evidence.
5. Audit task candidates against persisted tasks using semantic equivalence, not exact strings alone. Before calling a task “missed”, exclude duplicates, later restatements, completion evidence, other-owned work, and ambiguous commands.
6. Validate ownership with both `capture_owner` and source-segment `is_user`/speaker fields. A contradiction means “needs review”, not “the user's task”.
7. Treat conversation records as fragments. Inspect negative segment timestamps, overlap, and short gaps; group likely episodes before calculating topic or time allocation. Label any grouping threshold as a heuristic.
8. Check domain terms against surrounding context. Mark suspected corrections explicitly; never silently rewrite a transcript.
9. Rank findings by usefulness, evidence strength, and reversibility. Keep health, legal, financial, and relationship interpretations conservative.

## Required Output

| Field | Content |
|---|---|
| Observation | API/transcript fact with count, date, or source |
| Inference | Explicitly labeled hypothesis |
| Confidence | High, medium, or low with reason |
| Action | Smallest safe next step |

End with coverage limits: capture interval, missing sources, sample bias, and whether any Omi data was changed.

## Common Mistakes

- Reading UTC calendar dates as local dates.
- Treating `capture_owner=user` or a high confidence score as ground truth.
- Counting fragments as independent conversations or work sessions.
- Calling every unsaved candidate a dropped task.
- Turning two days of capture into a personality or health diagnosis.
