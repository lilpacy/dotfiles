# GitHub required-check source and identity

Use this when a pull request shows an old or red job after its workflow or merge policy changed.

## Evidence sequence

Set `repo`, `pr`, `base`, and `workflow` from repository and pull-request metadata; do not guess them. Resolve the base and head SHAs from the target pull request rather than the local checkout.

```bash
gh pr view "$pr" -R "$repo" --json baseRefName,baseRefOid,headRefOid,mergeable,mergeStateStatus,statusCheckRollup
base_sha=$(gh pr view "$pr" -R "$repo" --json baseRefOid --jq .baseRefOid)
head_sha=$(gh pr view "$pr" -R "$repo" --json headRefOid --jq .headRefOid)
gh api "repos/$repo/rules/branches/$base"
gh api "repos/$repo/rulesets?includes_parents=true" --paginate
gh api "repos/$repo/contents/.github/workflows/$workflow?ref=$base_sha" --jq .content | base64 --decode
gh api "repos/$repo/contents/.github/workflows/$workflow?ref=$head_sha" --jq .content | base64 --decode
```

Quote API endpoints containing `?` so shells such as zsh do not treat them as globs.

From effective rules, record only rulesets whose ref conditions apply to the base branch. For each `required_status_checks` rule, keep the context and integration ID. From the rollup, keep the check name, conclusion, workflow name, and details URL. Follow the details URL or Actions API when the workflow event is not already known.

For `pull_request_target`, compare the workflow file at the base ref with the pull-request head. GitHub executes the base-side definition even when steps later check out pull-request code. A renamed head-side job generally appears only after that definition reaches the base branch and a qualifying event starts a new run.

## Decision table

| Observation | Conclusion | Next check |
|---|---|---|
| Red job name is absent from applicable required contexts | The job is failing but not itself required | Find the actual blocker in required aggregates, reviews, threads, or in-progress checks |
| `pull_request_target` job name differs between base and head workflow files | The old displayed name comes from the base-side workflow definition | State when the head-side change becomes reachable; do not relabel the old run |
| Required aggregate is failed or pending | Merge remains blocked regardless of an optional job | Inspect that aggregate's constituent jobs and logs |
| Ruleset no longer requires a context but an old run remains red | Policy changed; historical check state did not | Verify effective rules and current merge state independently |
| Merge state is blocked without an obvious failed required context | Status checks alone do not explain the verdict | Inspect reviews, unresolved threads, freshness, merge method, and other branch rules |

## Reporting boundary

Do not say “the gate is still required” from the pull-request UI label alone. Report four separate facts:

1. which workflow definition produced the displayed job;
2. whether its context is currently required;
3. what currently blocks merge;
4. when the workflow rename or policy change becomes observable on a new run.
