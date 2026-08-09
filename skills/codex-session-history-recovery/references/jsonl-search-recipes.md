# JSONL Search Recipes

## Candidate discovery

Search for two or more distinctive anchors when possible:

```bash
rg -l -i --glob '*.jsonl' 'repository-name|distinctive-command' ~/.codex/sessions
```

An anchor appearing in a file does not prove the user discussed it. Codex session records can also contain injected instructions, tool output, and quoted prior text.

## Extract conversational messages

For a candidate JSONL file, isolate actual user and assistant message items:

```bash
jq -r '
  select(
    .type == "response_item"
    and .payload.type == "message"
    and (.payload.role == "user" or .payload.role == "assistant")
  )
  | "--- " + .payload.role + " ---\n"
    + ([.payload.content[]? | .text // .input_text // .output_text // empty] | join("\n"))
' candidate.jsonl
```

Adjust field selection only after inspecting the record shape; session formats can evolve.

## Confirmation checklist

- The anchor occurs in a genuine user message, not only in injected context.
- The session timestamp fits the user's recollection.
- A completion message or recorded artifact corroborates the claimed outcome.
- Any source line offered to the user points to the relevant exchange.
- Sensitive content is summarized or omitted rather than copied verbatim.
