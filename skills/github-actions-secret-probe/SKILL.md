---
name: github-actions-secret-probe
description: Safely verify a secret-dependent GitHub Actions capability on a same-repository branch before production workflow implementation, without retrieving the secret or leaving the probe workflow in the final diff.
---

# GitHub Actions Secret Probe

Use this when a CI capability must be measured in GitHub Actions because the required repository secret is unavailable locally.

## Safety boundary

- Never retrieve, print, encode, upload, or otherwise expose a secret value.
- Use only a same-repository branch; fork pull requests do not receive ordinary repository secrets.
- Give the probe the minimum token permissions, normally `contents: read`.
- Do not grant the model shell, write, or repository mutation authority merely to test an external API.
- Bound paid or remote operations by request count, timeout, redirect count, response bytes, protocol, and provider continuation count as applicable.
- For provider-managed tools, follow the current official stop/continuation protocol and fail closed when the continuation cap is reached.
- Treat search filters as candidate constraints, not fetch authorization. Revalidate every returned URL before fetching; path-root allowlists must reject queries, encoded traversal, and normalized paths outside the root.
- Print only non-sensitive validation summaries. Do not upload raw responses unless their contents were reviewed.

## Procedure

1. Inspect repository variable values and secret names only:

   ```bash
   gh variable list --repo OWNER/REPO
   gh secret list --repo OWNER/REPO
   ```

2. Add a temporary workflow with:
   - an exact `push.branches` match for the probe branch;
   - least-privilege `permissions`;
   - the existing secret mapped to the expected environment variable;
   - one bounded, read-only probe;
   - deterministic assertions that make missing or malformed results fail closed.

3. Commit and push the temporary workflow. A branch-specific `push` workflow can run before that workflow exists on the default branch.

4. Record the run URL and inspect its final status and sanitized output:

   ```bash
   gh run list --repo OWNER/REPO --branch BRANCH --limit 5
   gh run watch RUN_ID --repo OWNER/REPO --exit-status
   gh run view RUN_ID --repo OWNER/REPO --log
   ```

5. Delete the temporary workflow from the branch before opening the final PR. Keep only the smallest evidence artifact needed, usually a report linking the Actions run.

6. Verify that the final PR diff contains no probe workflow, secret, raw response, or production permission expansion.

## Acceptance criteria

- The Actions run completed and exercised the secret-dependent path.
- Logs show the secret masked and contain only the intended result summary.
- The requested resource and cost bounds were observed.
- The final tree no longer contains the temporary workflow.
- Any production implementation remains a separate, reviewable change.

## Known ceiling

This proves runtime feasibility, not production correctness. It does not settle source trust, retry policy, budgets, or automatic publication rules; keep those decisions explicit and fail closed until they are defined.
