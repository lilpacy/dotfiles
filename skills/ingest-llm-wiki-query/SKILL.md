---
name: ingest-llm-wiki-query
description: Ingest a completed agent conversation into an LLM Wiki repository that uses queries, Knowledge Deltas, Summaries, Entities, index.md, and log.md. Use when a user explicitly asks to ingest or add the current query/conversation to the wiki, especially in repositories governed by lilpacy/CLAUDE.md, and optionally commit, push, or open a PR afterward.
---

# Ingest an LLM Wiki Query

## Establish the repository contract

1. Read the repository instructions, `lilpacy/CLAUDE.md`, `lilpacy/index.md`, and the relevant existing Summary, Concept, and Entity pages.
2. Read the current templates under `lilpacy/schema/` before producing Delta, Summary, or Entity records.
3. Treat `queries/` as immutable raw data after generation. Do not update Concepts during query ingest; record only Concept impact hints in the Delta.
4. Render generated Summary, Concept, and Entity math with Obsidian syntax: use `$...$` inline and put each `$$` block delimiter on its own line. Do not use `\[...\]` or `\(...\)` outside immutable transcripts or code examples.

## Extract the transcript faithfully

1. Run `ruby scripts/export_query_transcript.rb` without arguments and identify the intended session by its displayed question and timestamp. Never select the latest session blindly.
2. Run the exporter with the exact session JSONL and a descriptive title.
3. Save the emitted Markdown without hand-editing its content. Freeze the transcript at that extraction point even if the live session later continues.
4. Preserve intentional Markdown trailing spaces in the generated transcript; exclude that immutable file from whitespace-only checks instead of rewriting it.

## Build grounded wiki projections

1. Compute the transcript SHA-256. Name the Delta with the first 12 hex characters and record the full hash as `source_snapshot`.
2. Compare the transcript with the existing vault and record only new, refining, reinforcing, contradicting, or uncertain claims.
3. Copy every Delta `evidence` value as an exact contiguous transcript fragment.
4. Project every Delta `summary_text` verbatim into its declared required Summary section.
5. Update an Entity only for reusable facts or relations about an identifiable target. Point every Fact or Relation to the exact Delta block.
6. Register the Delta and Summary in `index.md`, keep the existing Entity catalog entry unless its description truly changed, and append a `query` entry to `log.md`.

Use the repository's deterministic ID algorithms when available. In the current pipeline:

- Delta ID: SHA-256 of the repository `source_link` path without `.md` or wikilink brackets, classification, claim, and evidence joined by NUL; use the first 12 hex characters. For query ingest, this is `queries/YYYY-MM-DD Title`, matching `target_filename.delete_suffix(".md")` in `scripts/pi_ingest_apply.rb`, not the frontmatter value `[[queries/...]]`.
- Fact ID: SHA-256 of entity path, attribute, value, and Delta ID joined by NUL; use the first 12 hex characters.

## Verify before committing

Run from the repository root:

```bash
ruby scripts/wiki_pipeline_lint.rb .
ruby -Itest test/wiki_pipeline_lint_test.rb
ruby -Itest test/pi_ingest_apply_test.rb
ruby -Itest test/export_query_transcript_test.rb
```

Do not pass `lilpacy` to `wiki_pipeline_lint.rb`; the script appends `lilpacy` internally, so that would inspect the wrong path.

Also verify programmatically that:

- the transcript SHA-256 equals the Delta `source_snapshot`;
- every Delta evidence fragment occurs exactly in the transcript;
- every `summary_text` occurs in its declared Summary section;
- every Entity evidence link resolves to an existing Delta block;
- only intended files are staged.

When the user requests commit or PR creation, follow the repository's commit and review skills, run the required post-commit read-only review, push only the task branch, and open the PR with verification results.
