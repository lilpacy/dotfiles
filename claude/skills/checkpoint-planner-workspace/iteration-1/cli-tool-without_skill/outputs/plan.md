# Plan: linear-sync CLI Tool

A TypeScript/Node.js CLI that pulls assigned Linear issues and writes them as `.md` files to a local folder. Designed to run as a cron job every 5 minutes.

---

## 1. Project Setup

- **Name:** `linear-sync`
- **Runtime:** Node.js (>=18), TypeScript
- **Package manager:** npm
- **Key dependencies:**
  - `@linear/sdk` — official Linear GraphQL client
  - `commander` — CLI argument parsing
  - `dotenv` — load API key from `.env`
- **Build:** `tsc` to compile to `dist/`, `bin` field in `package.json` pointing to `dist/index.js`
- Install globally via `npm link` during development; distribute as a brew tap or npx-runnable package later.

## 2. Authentication

- Linear personal API key stored in `~/.config/linear-sync/.env` (or `LINEAR_API_KEY` env var).
- On first run, if no key found, print instructions and exit with code 1.
- No OAuth flow needed for a personal CLI tool.

## 3. Core Sync Logic

### 3.1 Fetch Issues

```
GET assigned issues via @linear/sdk
  - filter: assignee = me
  - include: title, identifier, description, state, priority, labels, project, cycle, createdAt, updatedAt, url
  - pagination: cursor-based, fetch all pages
```

### 3.2 Generate Markdown

Each issue becomes one file: `<output-dir>/<IDENTIFIER>.md`

Template:
```markdown
---
id: LIL-42
title: Implement caching layer
state: In Progress
priority: Urgent
labels: [backend, performance]
project: Core Infrastructure
cycle: Sprint 24
url: https://linear.app/...
updated_at: 2026-03-07T12:00:00Z
synced_at: 2026-03-07T12:05:00Z
---

# LIL-42: Implement caching layer

<issue description body in markdown>
```

- YAML frontmatter enables structured grep (`grep -l "state: In Progress" ./issues/`).
- `synced_at` tracks when the file was last written.

### 3.3 Write Strategy

- Compare `updated_at` from Linear with the `updated_at` in the existing file's frontmatter.
- **Skip write if unchanged** — avoids unnecessary disk churn and preserves file mtime for editor integrations.
- Delete local `.md` files whose identifiers no longer appear in the fetched set (issue archived/unassigned). Gate this behind a `--prune` flag to be safe.

## 4. CLI Interface

```
linear-sync [options]

Options:
  -o, --output <dir>    Output directory (default: ~/linear-issues)
  -a, --all             Sync all issues, not just assigned to me
  --include-completed   Include completed/cancelled issues (excluded by default)
  --prune               Remove local files for issues no longer matching filters
  --dry-run             Print what would change without writing
  --verbose             Print detailed logs
  -h, --help            Show help
```

## 5. File Structure

```
linear-sync/
  src/
    index.ts          # CLI entry point (commander setup)
    client.ts         # Linear SDK wrapper, auth loading
    fetch.ts          # Issue fetching + pagination
    render.ts         # Issue -> markdown string conversion
    sync.ts           # Diff logic, write/prune files
    types.ts          # Shared types
  tsconfig.json
  package.json
  .env.example
```

Six source files. Each under 150 lines. No over-engineering.

## 6. Error Handling

- Network failure: log error, exit 1 (cron will retry next cycle).
- Rate limiting: `@linear/sdk` handles retries internally; add a 60s backoff on 429.
- Partial failure: write what you can, log failures, exit 1.
- Lock file (`<output-dir>/.linear-sync.lock`): prevent overlapping cron runs. Stale lock (>5 min) gets force-removed.

## 7. Cron Setup

```bash
# crontab -e
*/5 * * * * /usr/local/bin/linear-sync -o ~/linear-issues --prune >> ~/linear-issues/.sync.log 2>&1
```

- Log rotation: the user can use `logrotate` or just `tail -1000` periodically.
- Alternatively, use launchd plist on macOS for better daemon management.

## 8. Implementation Order

| Step | Task | Estimate |
|------|------|----------|
| 1 | `npm init`, install deps, tsconfig, commander boilerplate | 15 min |
| 2 | `client.ts` — auth loading + Linear SDK init | 15 min |
| 3 | `fetch.ts` — paginated issue fetch | 30 min |
| 4 | `render.ts` — markdown template rendering | 20 min |
| 5 | `sync.ts` — diff, write, prune logic + lock file | 30 min |
| 6 | `index.ts` — wire everything together with commander | 20 min |
| 7 | Manual testing against real Linear workspace | 15 min |
| 8 | Cron setup + launchd plist | 10 min |
| **Total** | | **~2.5 hours** |

## 9. Risks and Mitigations

| Risk | Mitigation |
|------|-----------|
| Linear API rate limit (1500 req/hr) | Fetch only updated issues using `updatedAt > last_sync` filter after first full sync. Store last sync timestamp in `<output-dir>/.last-sync`. |
| Large number of issues (>1000) | Pagination already handled. Filesystem can handle tens of thousands of small files. |
| Concurrent cron runs | Lock file with PID check. |
| API key leak | `.env` file with 600 permissions. Never log the key. |

## 10. Future Extensions (Out of Scope for v1)

- Bidirectional sync (edit markdown -> push to Linear).
- Watch mode (`--watch`) using filesystem events instead of cron.
- Comment sync (append comments as a section in the markdown).
- Filtering by team, project, or label via CLI flags.
