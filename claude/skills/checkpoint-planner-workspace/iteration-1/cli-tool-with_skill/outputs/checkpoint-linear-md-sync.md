# Checkpoint Plan: Linear-to-Markdown Sync CLI

**Created**: 2026-03-07
**Status**: Active

## Goal

Build a TypeScript CLI tool that syncs the user's assigned Linear issues to a local folder as markdown files, runnable as a 5-minute cron job.

## Constraints

- Must be TypeScript / Node.js
- Must work unattended as a cron job (no interactive auth prompts)
- Linear API rate limits must not be exceeded at 5-minute intervals
- Output must be plain .md files searchable with grep and standard editors
- Should not require global npm install (use npx or local install)

## What I Know

- Linear has an official Node.js SDK (`@linear/sdk`) that supports personal API tokens
- Linear's GraphQL API exposes issues with title, description (markdown), state, labels, assignee, priority, etc.
- The SDK supports filtering issues by assignee and updated date
- Personal API tokens can be created in Linear Settings > API
- Node.js has built-in `fs` module for writing files; no special dependencies needed for markdown output
- cron on macOS can be configured via `crontab -e` or launchd plist

## What I Don't Know

- **[CRITICAL]** Linear API rate limits: what are the exact limits, and will a full re-sync every 5 minutes stay within them? Need to verify before building incremental sync logic.
- Does the Linear SDK support a "modified since" / `updatedAt` filter efficiently, or do we need to fetch all issues and diff locally?
- How large is the typical issue set? If the user has 500+ assigned issues, a full fetch every 5 minutes may be slow.
- Should deleted/archived issues also be removed from the local folder, or left as stale files?
- What markdown frontmatter format works best for grep workflows? (YAML frontmatter with id, state, priority, labels?)

## First Proof (Checkpoint 1)

**What to do**: Scaffold a minimal TypeScript script that authenticates with the Linear API using a personal token, fetches one assigned issue, and writes it to a `.md` file with YAML frontmatter.

**What "passing" looks like**:
- Running `npx tsx sync.ts` produces a file like `issues/LIL-42.md` containing the issue title, state, and description body
- The API token is read from an environment variable (`LINEAR_API_KEY`)
- No crashes, no auth errors, the markdown renders correctly when opened in an editor

## What Could Make This Plan Wrong

- Linear's rate limits could be too restrictive for polling every 5 minutes with many issues (mitigation: use `updatedAt` filter for incremental sync)
- The user's issue count could be so large that even incremental sync is slow (mitigation: paginate and only fetch changed issues)
- Linear could change their API or SDK in ways that break the tool (low risk, but pin SDK version)
- The markdown format chosen might not suit the user's grep patterns (mitigation: make frontmatter fields configurable, iterate after checkpoint 1)
- cron environment might not have the right PATH or node version (mitigation: use absolute paths in crontab, test early)

## Dependencies

- `@linear/sdk` npm package
- `tsx` for running TypeScript without a build step (or compile with `tsc`)
- A valid Linear personal API token
- Node.js >= 18 (for native fetch support in the SDK)

## Edge Cases

- Issue description is null or empty (write file with frontmatter only)
- Issue identifier contains characters invalid for filenames (unlikely with Linear's `TEAM-123` format, but sanitize anyway)
- Multiple syncs running concurrently from overlapping crons (use a lockfile or PID check)
- Network failure mid-sync (write to temp files, then atomic rename)
- Issue is deleted/archived in Linear but .md file still exists locally (need a cleanup strategy)
- Token is expired or revoked (exit with clear error message, don't silently produce empty output)

## Checkpoints

| # | Checkpoint | Pass Criteria | Review? |
|---|-----------|--------------|---------|
| 1 | Auth + single issue fetch + write .md | `npx tsx sync.ts` produces one valid .md file | Yes |
| 2 | Fetch all assigned issues, write all .md files | All assigned issues appear as files in `issues/` dir | Yes |
| 3 | Incremental sync using `updatedAt` filter | Only changed issues are re-fetched; unchanged files are untouched | |
| 4 | CLI packaging with config (token, output dir, filter) | `npx linear-md-sync --dir ./issues` works | Yes |
| 5 | Cron setup + error handling + lockfile | Runs unattended every 5 min, logs errors, no duplicate runs | Yes |

## Definition of Done

- CLI tool installable via `npx` or local `npm install`
- Reads Linear API token from env var or `.env` file
- Syncs all assigned issues to configurable output directory
- Each issue is a `.md` file named `<identifier>.md` with YAML frontmatter (id, title, state, priority, labels, updated date)
- Incremental sync: only fetches issues updated since last sync
- Handles errors gracefully (network, auth, rate limits) with clear log messages
- Lockfile prevents concurrent runs
- Tested manually with real Linear data
- cron job documented (example crontab entry in README)

## Review Point

**When**: After Checkpoint 1 is complete (estimated: 30-60 minutes of work, roughly 10-15% of total effort).

**Questions to ask at review**:
- Did the Linear SDK work smoothly, or were there surprises?
- Is the rate limit situation clear now? (Check response headers for rate limit info.)
- Does the markdown format feel right when grepping? Try a few searches.
- Is `tsx` the right runner, or should we add a build step?
