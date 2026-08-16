# JSONL Search Recipes

## Candidate discovery

Search for two or more distinctive anchors when possible:

```bash
rg -l -i --glob '*.jsonl' 'repository-name|distinctive-command' ~/.codex/sessions
```

An anchor appearing in a file does not prove the user discussed it. Codex session records can also contain injected instructions, tool output, and quoted prior text.

## Extract conversational messages

For a candidate JSONL file, isolate user and assistant message items with ordering evidence:

```bash
jq -r '
  select(
    .type == "response_item"
    and .payload.type == "message"
    and (.payload.role == "user" or .payload.role == "assistant")
  )
  | "--- ordinal=" + ((.ordinal // "?") | tostring)
    + " timestamp=" + (.timestamp // "?")
    + " role=" + .payload.role + " ---\n"
    + ([.payload.content[]? | .text // .input_text // .output_text // empty] | join("\n"))
' candidate.jsonl
```

Adjust field selection only after inspecting the record shape; session formats can evolve. On very large transcripts, filter by ordinal or timestamp ranges after this first structural pass instead of dumping encrypted reasoning and tool payloads.

Role filtering reduces noise but does not establish provenance. A `role=user` message can still contain injected `AGENTS.md`, `<environment_context>`, or other harness context. Classify those blocks separately and require a natural-language user request before attributing intent.

## Confirmation checklist

- The anchor occurs in a genuine natural-language user request, not only in injected context.
- The session timestamp and ordinal sequence fit the user's recollection.
- A completion message or recorded artifact corroborates the claimed outcome.
- Any source line offered to the user points to the relevant exchange.
- Sensitive content is summarized or omitted rather than copied verbatim.
