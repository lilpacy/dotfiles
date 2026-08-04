# GitHub review API operations

Use these operations only after the approval required by `SKILL.md`.

## Shared preparation

```bash
GR_REPO='OWNER/REPO'
GR_PR_NUMBER=123

GR_PR_ID=$(gh pr view "$GR_PR_NUMBER" -R "$GR_REPO" --json id --jq '.id')
GR_HEAD_SHA=$(gh pr view "$GR_PR_NUMBER" -R "$GR_REPO" --json headRefOid --jq '.headRefOid')
```

For line comments:

- `RIGHT` targets the new/current side of the diff.
- `LEFT` targets a removed/previous line.
- `line` must be commentable in the current PR diff.
- Re-read `GR_HEAD_SHA` immediately before writing.

## Mode 1: one standalone comment

Send one request per approved comment:

```bash
gh api \
  --method POST \
  "repos/$GR_REPO/pulls/$GR_PR_NUMBER/comments" \
  -f commit_id="$GR_HEAD_SHA" \
  -f path='path/to/file' \
  -F line=42 \
  -f side='RIGHT' \
  -f body='Approved review comment'
```

Capture `html_url` from the response and report it.

## Mode 2: one atomic review

Submit the summary, event, and all inline comments in one request:

```bash
gh api \
  --method POST \
  "repos/$GR_REPO/pulls/$GR_PR_NUMBER/reviews" \
  --input - <<JSON
{
  "commit_id": "$GR_HEAD_SHA",
  "body": "Approved review summary",
  "event": "REQUEST_CHANGES",
  "comments": [
    {
      "path": "path/to/file",
      "line": 42,
      "side": "RIGHT",
      "body": "First approved review comment"
    },
    {
      "path": "path/to/other-file",
      "line": 17,
      "side": "RIGHT",
      "body": "Second approved review comment"
    }
  ]
}
JSON
```

Build JSON with a structured encoder when comment bodies contain quotes, backslashes, or multiline suggestion blocks. Do not interpolate unescaped user text into JSON.

## Mode 3: incremental pending review

### Start a pending review

Do this once, after the first draft has been approved:

```bash
GR_REVIEW_ID=$(
  gh api graphql \
    -f query='
      mutation($pullRequestId: ID!, $commitOID: GitObjectID!) {
        addPullRequestReview(input: {
          pullRequestId: $pullRequestId
          commitOID: $commitOID
        }) {
          pullRequestReview {
            id
            state
          }
        }
      }
    ' \
    -f pullRequestId="$GR_PR_ID" \
    -f commitOID="$GR_HEAD_SHA" \
    --jq '.data.addPullRequestReview.pullRequestReview.id'
)
```

The omitted event keeps the review in `PENDING`.

### Add one approved review thread

Repeat once per approved comment:

```bash
gh api graphql \
  -f query='
    mutation(
      $reviewId: ID!
      $path: String!
      $line: Int!
      $body: String!
    ) {
      addPullRequestReviewThread(input: {
        pullRequestReviewId: $reviewId
        path: $path
        line: $line
        side: RIGHT
        body: $body
      }) {
        thread {
          id
        }
      }
    }
  ' \
  -f reviewId="$GR_REVIEW_ID" \
  -f path='path/to/file' \
  -F line=42 \
  -f body='Approved review comment'
```

Use `startLine` and `startSide` only for an approved multi-line range.

### Submit the pending review

Submit only after the summary and event are approved:

```bash
gh api graphql \
  -f query='
    mutation($reviewId: ID!, $body: String!) {
      submitPullRequestReview(input: {
        pullRequestReviewId: $reviewId
        event: REQUEST_CHANGES
        body: $body
      }) {
        pullRequestReview {
          id
          state
          url
        }
      }
    }
  ' \
  -f reviewId="$GR_REVIEW_ID" \
  -f body='Approved review summary'
```

Replace `REQUEST_CHANGES` with the approved `COMMENT` or `APPROVE` event when applicable.

## Verification

After a write, verify the returned object and read the resulting state:

```bash
gh api --paginate \
  "repos/$GR_REPO/pulls/$GR_PR_NUMBER/reviews"

gh api --paginate \
  "repos/$GR_REPO/pulls/$GR_PR_NUMBER/comments"
```

Match the returned review or comment ID instead of assuming the latest item belongs to this operation.
