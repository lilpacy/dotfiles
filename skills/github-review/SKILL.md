---
name: github-review
description: Collaboratively review GitHub pull requests, verify a user's understanding through a no-post question-by-question walkthrough, or post only user-approved inline comments, suggestions, and review summaries through gh. Use whenever an agent is asked to review or understand a GitHub PR, help prepare or post GitHub review comments, propose line-level changes, request changes, approve a PR, or reconcile the user's understanding against the PR.
---

# GitHub Review

Help the user reach sound review decisions or a traceably complete understanding of a PR. Inspect first, ask one substantive question at a time, and either reconcile the user's understanding without posting or turn approved answers into GitHub reviews.

## Non-negotiable rules

- Treat GitHub reads as safe and GitHub writes as external side effects.
- Never post, submit, approve, request changes, edit, resolve, dismiss, or delete without showing the exact proposed action and receiving `y`.
- Ask only one question at a time. Do not present the complete question list to the user at once.
- Establish evidence before raising a finding. Inspect the PR diff, surrounding code or docs, tests, linked issues, and existing review comments.
- Search the repository before claiming that a requirement, definition, test, or behavior is missing.
- Do not post duplicate, speculative, purely stylistic, or non-actionable comments.
- Preserve the user's language and intent. Do not attribute wording to the user inside the GitHub comment.
- Re-read the current PR head SHA and affected diff before each write. If either changed, revalidate the affected draft first.
- Use `gh` with the authenticated user's account. Never expose tokens.
- In understanding-only mode, never write to GitHub. Switching to a posting mode requires an explicit user request.

Read [references/github-api.md](references/github-api.md) before performing any GitHub write.

## Workflow

### 1. Resolve the review target

Identify the repository and pull request. If either is ambiguous, ask one concise question.

Verify:

- `gh auth status`
- PR URL, number, base branch, head branch, head SHA, author, and review state
- changed files and complete diff
- repository review instructions and relevant source-of-truth documents
- existing reviews and inline comments

Do not write to GitHub during this step.

### 2. Select the delivery mode

Ask the user to select exactly one mode:

| Mode | Delivery behavior |
|---|---|
| 1. Immediate single comments | After each answer, draft one inline comment and optional suggestion, ask `y/n`, then post that comment immediately with one REST request. |
| 2. Atomic review | Collect all answers without posting. Then show all inline drafts, summary, and review event, ask `y/n`, and submit everything in one REST request. |
| 3. Incremental pending review | After each answer, draft one inline comment and optional suggestion, ask `y/n`, then add it to one pending review. After all findings, show the summary and review event, ask `y/n`, then submit the pending review separately. |
| 4. Understanding report only | Never post. Test the user's understanding one question at a time, correct gaps with evidence, then reconcile the user's final understanding against the latest PR and produce a structured report. |

Do not choose on the user's behalf. Explain only the practical difference if asked.

### 3. Build the private question list

Inspect the PR before questioning the user. Build and maintain a private ordered list of review points or understanding checkpoints.

For every candidate point, record:

- severity and user impact
- exact file and diff line
- observed evidence
- related implementation, tests, requirements, design docs, and existing comments
- what remains unknowable from the repository
- the single decision or fact needed from the user
- a likely correction, if one is supported by evidence

Order by bugs, security or data loss, behavioral regressions, contract conflicts, missing tests, and then maintainability. Remove a point when repository evidence already answers it.

For mode 4, cover the PR rather than only suspected defects. Include every applicable category:

- purpose and user-visible outcome
- included and excluded scope
- actors, permissions, and ownership
- main flow, state transitions, and data lifecycle
- boundary conditions, errors, and rollback behavior
- compatibility, migration, deployment, and operational effects
- tests and acceptance evidence
- dependencies, unresolved decisions, and known risks

Mark categories as non-applicable only with PR or repository evidence.

### 4. Ask one review question

For the highest-priority unresolved point:

1. State the observed evidence briefly.
2. Explain the concrete ambiguity or risk.
3. Ask one question that resolves one decision.
4. Wait for the answer.

Do not ask broad questions such as "What do you think?" Offer bounded choices when they clarify a real decision, while allowing free-form answers.

In mode 4, prefer asking the user to explain a point in their own words before showing the PR's answer. Compare the response with evidence. If it is incomplete or inconsistent, explain the specific gap and ask one follow-up question. Record the user's latest corrected understanding.

### 5. Turn the answer into a review draft in modes 1-3

After the answer:

1. Reconcile it with repository evidence.
2. If the answer shows there is no issue, remove the point and do not create a comment.
3. Otherwise draft a concise GitHub comment containing:
   - what is inconsistent or risky;
   - why it matters;
   - the requested outcome or proposed correction.
4. Add a GitHub `suggestion` block only when an exact replacement is supported and fits the selected diff lines.
5. Show the destination path, line, comment body, and suggestion exactly as they will be posted.

Never invent product requirements inside a suggestion. If the decision is still unknown, request clarification or propose recording it as unresolved instead.

### 6. Confirm and deliver by mode

#### Mode 1: Immediate single comments

For each draft, ask: `このコメントを投稿しますか？ (y/n)`

- On `y`, revalidate the head SHA and diff line, then post one standalone inline comment.
- On `n`, do not write. Ask whether to revise or skip, one question at a time.
- Report the resulting comment URL, then continue to the next review question.

Do not create a review summary unless the user separately requests one.

#### Mode 2: Atomic review

Do not write while gathering answers. After all review questions are resolved:

1. Draft the complete inline comment set.
2. Draft a concise overall summary.
3. Propose one event: `COMMENT`, `REQUEST_CHANGES`, or `APPROVE`.
4. Show the exact package and ask: `この内容でレビューを送信しますか？ (y/n)`

On `y`, revalidate every line and submit the summary, event, and all comments in one request. On `n`, do not submit anything; revise the package and confirm again.

#### Mode 3: Incremental pending review

- On the first approved draft, create one pending review and add the first thread.
- For each later draft, ask `y/n` and add an approved thread to that same pending review with a separate request.
- Never create a second pending review when one from the current user already exists without asking how to handle it.
- After all review questions are resolved, draft the overall summary and propose the review event.
- Show the exact summary and event, then ask: `この内容で保留中のレビューを送信しますか？ (y/n)`
- On `y`, submit the pending review in a separate request. On `n`, leave it pending and state that clearly.

If the user stops after a pending review has been created, report that it remains private and pending. Ask before deleting it.

#### Mode 4: Understanding report only

Do not create comments, reviews, drafts, or pending reviews.

For each checkpoint:

1. Ask one question and wait.
2. Compare the answer with the PR and its source-of-truth context.
3. Mark it internally as `一致`, `相違あり`, or `未確認`.
4. For `相違あり`, explain the evidence and continue with one focused follow-up until the user's understanding is corrected or explicitly left unresolved.
5. Preserve the user's final stated understanding for the report.

After all checkpoints:

1. Re-fetch the PR head SHA and complete diff.
2. If the head changed, re-inspect affected files and re-open any invalidated checkpoints one question at a time.
3. Reconcile every recorded understanding against the latest PR.
4. Produce this report:

```markdown
# PR理解確認レポート

## 判定
一致 / 相違あり / 未確認事項あり / 相違あり・未確認事項あり

## 対象
- PR:
- 確認したhead SHA:
- 確認範囲:

## 理解の照合
| 論点 | ユーザーの最終理解 | PR上の根拠 | 判定 |
|---|---|---|---|

## 解消した相違
| 論点 | 当初の理解 | 最終理解 | 根拠 |
|---|---|---|---|

## 未確認・未解決
| 論点 | 不足している確認 | PR理解への影響 |
|---|---|---|
```

Determine the report status from the remaining checkpoints:

| Remaining discrepancy | Remaining unknown | Status |
|---|---|---|
| No | No | `一致` |
| Yes | No | `相違あり` |
| No | Yes | `未確認事項あり` |
| Yes | Yes | `相違あり・未確認事項あり` |

Never claim the user's understanding is complete merely because all planned questions were asked.

### 7. Finish

Report:

- selected delivery mode
- posted comment URLs or submitted review URL
- final review event and state
- skipped or unresolved review points

For mode 4, replace posting details with the understanding report, latest head SHA, coverage, and remaining discrepancies or unknowns.

For modes 1-3, do not claim success until the API response and resulting GitHub state have been checked. For mode 4, do not claim completion until the latest head SHA and every applicable checkpoint have been reconciled.

## Review comment standard

Prefer direct, natural language:

```markdown
この条件では、キャンセル後も以前の担当者が対象データを閲覧できます。
キャンセル完了時に閲覧権限も失効する要件へ揃えてください。
```

Use a replacement only when exact:

````markdown
```suggestion
replacement text
```
````

Avoid:

- praise used as padding
- labels such as "blocking" without demonstrated impact
- implementation prescriptions when the concern is a product requirement
- restating content already defined elsewhere
- suggestions that expand the PR scope without user agreement
