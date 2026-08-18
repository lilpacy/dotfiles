# Pull-request mergeability freshness

Use this check before explaining why a pull request is blocked or whether a recent base-branch change already addressed the reported problem.

## Failure pattern

A diagnosis can accurately describe the checks attached to the pull request's current base snapshot while still being outdated. The named base branch may have advanced after that snapshot, including merged changes to workflows, build modes, or gate policy. Existing check runs, the PR's `baseRefOid`, the current branch HEAD, and current rulesets are separate observations with different update times.

## Verification sequence

1. Read the pull request snapshot and checks:

   ```bash
   gh pr view <pr> --json baseRefName,baseRefOid,headRefOid,mergeStateStatus,statusCheckRollup
   gh pr checks <pr> --required
   ```

2. Query the named base branch independently:

   ```bash
   gh api repos/<owner>/<repo>/branches/<base> --jq '{sha:.commit.sha,protected:.protected}'
   ```

3. If the branch HEAD differs from `baseRefOid`, inspect the commits and recently merged pull requests before drawing a conclusion:

   ```bash
   gh api 'repos/<owner>/<repo>/commits?sha=<base>&per_page=20' \
     --jq '.[] | [.sha, .commit.author.date, (.commit.message | split("\n")[0])] | @tsv'
   gh pr list --state merged --base <base> --limit 20 \
     --json number,title,mergedAt,mergeCommit,url
   ```

4. Read branch protection or applicable rulesets separately from the check runs already attached to the PR. A removed required context can remain red on an old run without being the current blocker; an aggregate required check can still block because one of its internal jobs failed.

5. Report all four provenance points: PR base snapshot, latest base branch HEAD, current policy/ruleset, and check-run SHA. State whether updating the PR with the base branch would change the diagnosis; do not imply that a base update fixes a separate failing policy unless the changed workflow actually addresses it.

## Completion boundary

The diagnosis is current only when the latest base branch HEAD has been checked at the time of investigation. If it differs from the PR snapshot, distinguish:

- what blocks the PR now;
- what changed later on the base branch;
- what is expected after the PR incorporates that change.
