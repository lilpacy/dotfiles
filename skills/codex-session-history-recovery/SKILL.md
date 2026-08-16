---
name: codex-session-history-recovery
description: Locate, identify, and safely summarize prior local Codex conversations from session JSONL when a user asks whether an earlier task, decision, or implementation can be recovered.
---

# Codex Session History Recovery

Recover evidence from local Codex session logs without confusing injected instructions, tool output, or repeated context with actual user requests.

## Use This Skill When

- The user asks whether Codex remembers or can find a previous conversation.
- A repository, URL, command, feature name, or outcome must be traced back to the session where it was discussed.
- A past implementation decision needs to be reconstructed from local conversation records.

Do not use this skill when the current thread already contains the needed exchange.

## Workflow

1. State the boundary: do not claim personal memory of another thread before locating evidence.
2. Search the local session store broadly for distinctive, non-secret anchors such as repository names, URLs, feature names, or command names.
3. Treat raw text matches only as candidates. The same anchor can occur in injected `AGENTS.md`, tool output, quoted history, or a later summary.
4. Parse candidate JSONL and isolate `response_item` messages whose role is `user` or `assistant`.
5. Treat role filtering as noise reduction, not proof of user intent. A `user` record can still contain injected `AGENTS.md`, `<environment_context>`, or other harness context; classify these separately from the user's natural-language request.
6. Compare the genuine user requests, timestamps, ordinals, session ID, and assistant completion messages to identify the relevant session.
7. Report the smallest useful result: session identity, approximate time, request, outcome, and a local source link when helpful.
8. Warn before exposing a full transcript if it contains credentials, incident details, personal data, or other sensitive material.

## Evidence Standard

A filename match is not enough. Confirm at least one genuine user message and one corroborating item such as:

- the assistant's completion message;
- a command result tied to the requested work;
- a commit hash or repository state recorded in the session;
- a later user message acknowledging the result.

Separate confirmed facts from reconstruction. If only a candidate match exists, label it as unconfirmed.

## Search Discipline

- Prefer `rg` for candidate discovery.
- Prefer structured JSON parsing over reading raw JSONL dumps.
- Search multiple anchors when common terms create noise.
- Do not print entire tool outputs merely to prove a match.
- Do not copy session files into a repository.
- Never include secrets in the response, even when they are expired.

See [JSONL search recipes](references/jsonl-search-recipes.md) for compact extraction commands and false-positive checks.
When implementing or debugging transcript readers, see [JSONL record boundaries](references/jsonl-record-boundaries.md) before choosing a line-splitting API.

## Output

Lead with whether the conversation was found. Then provide only the identifiers and facts the user needs. Use a compact table when several exact fields must be compared; otherwise use prose.

If no session is confirmed, say which stores and anchors were checked without presenting guesses as history.
