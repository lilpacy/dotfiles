# Post-validation change-impact decision

Use this after a successful expensive test run when a merge, rebase, conflict resolution, or metadata edit creates a newer pull-request head.

## Evidence to compare

Record the commit and merged tree actually exercised by the successful run. Compare that validated tree with the current candidate tree. Do not decide from the new head SHA alone, and do not assume that a base-branch update changed the application.

Inspect both the changed paths and their build meaning. Markdown can be executable when it drives code generation, tests, packaging, or deployed application content; a source-looking file can also be irrelevant to the exercised product. Repository policy remains authoritative.

| Semantic change since validated tree | Default verification |
|---|---|
| Non-executable prose or PR metadata only | Documentation/policy checks; no full E2E |
| Conflict resolution changes only non-executable docs | Review the resolved text and run docs checks; retain prior E2E evidence |
| Runtime code, dependencies, build inputs, schema, fixtures, or E2E tests changed | Run the smallest suite that covers the change; full E2E only when impact crosses the configured threshold |
| Application tree is identical but commit metadata or ancestry changed | Retain prior test evidence and record the provenance comparison |
| Repository policy explicitly mandates a rerun | Follow the policy even when semantic impact is low |

## Reporting

State exactly what the previous run validated and what changed afterward. Say “prior E2E remains applicable to the unchanged application tree” rather than claiming that the newest commit itself was executed.
