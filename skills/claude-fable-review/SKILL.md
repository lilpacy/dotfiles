---
name: claude-fable-review
description: Use only when the user explicitly asks for Fable/Claude review. Runs claude -p in streaming review mode with the configured Fable model, constrains tools for read-only review plus currentness checks, handles resume, and defines review timeout semantics.
---

# Claude Fable Review

## Trigger Rule

- Use this skill only when the user explicitly asks for Fable review, Claude review, or to consult Fable.
- Do not auto-trigger this skill for generic "review", planning, or post-commit review requests.
- Default review path remains `codex-exec-review` unless the user explicitly selects Fable.

## When Invoked

- Before presenting an implementation plan to the user, run `claude -p` with Fable to review the plan if the user explicitly asked for Fable review.
- After a non-trivial commit, run `claude -p` with Fable to review the committed change if the user explicitly asked for Fable review.
- Repeat review up to 3 times. Stop when no critical issue remains.
- Do not replace a requested Fable review with local tests or your own judgment.

## Review Command Rules

- Use `env claude -p` to avoid shell aliases such as `claude --dangerously-skip-permissions`.
- Use `CLAUDE_REVIEW_MODEL=global.anthropic.claude-fable-5`. Do not read the review model from the normal runtime model setting.
- Pass `--model "$CLAUDE_REVIEW_MODEL"` explicitly. Do not rely on the root `"model"` setting.
- Use `CLAUDE_REVIEW_EFFORT=${CLAUDE_REVIEW_EFFORT:-medium}` and pass `--effort "$CLAUDE_REVIEW_EFFORT"`.
- Do not pass `/Users/lilpacy/dotfiles/claude/settings.json` as the runtime settings file. Its normal permissions are broader than review mode.
- Use `--safe-mode` and a minimal review settings JSON. Do not use `--bare` for default reviews because Claude Code 2.1.197 exposes only `Read` in that mode, even when `WebFetch` is requested.
- Use `--permission-mode default`. Do not use `--permission-mode plan` for default reviews because it suppresses `WebFetch`, `Grep`, `Glob`, and `Bash` in the measured review setup.
- Prefer `--output-format stream-json --include-partial-messages --verbose` so progress remains visible while the final result is still machine-checkable.
- Allow `Bash` broadly and control risk with a denylist plus prompt constraints. Fable review quality depends on being able to run unknown local CLI introspection such as `--help`, `--version`, `--default-config`, status, and list commands without adding one-off allowlist entries.
- Keep the denylist focused on external review/agent launches, destructive git commands, obvious filesystem mutation, install/deploy entry points, and code execution snippets. Do not deny broad test/build command names because that also blocks their `--help` output; rely on the review prompt to forbid running tests/builds.
- Allow `WebFetch` by default for currentness checks against public primary sources. Request `WebSearch` and `Fetch` too, but do not require them in environments where Claude Code does not expose those tools.
- Instruct the reviewer not to paste private code, secrets, env values, customer data, or large local diffs into web queries.
- Instruct the reviewer not to run tests, build, format, install, generation, mutation, deployment, or external review commands.
- Instruct the reviewer not to start another `claude -p`, `codex exec`, or `mcp__ais` call.
- Instruct the reviewer to report only critical issues and to check whether the answer is out of date or deprecated.

## Initial Review Template

Set `PLAN_OR_DIFF_REF` to the full path, commit ref, or concise description being reviewed.

```bash
set -o pipefail

CLAUDE_MAIN_SETTINGS=/Users/lilpacy/dotfiles/claude/settings.json
CLAUDE_REVIEW_MODEL=global.anthropic.claude-fable-5
CLAUDE_REVIEW_EFFORT=${CLAUDE_REVIEW_EFFORT:-medium}
REVIEW_LOG=${REVIEW_LOG:-review-result.jsonl}
CLAUDE_REVIEW_SETTINGS_JSON=$(jq --arg review_model "$CLAUDE_REVIEW_MODEL" -c '{
  env: {
    CLAUDE_CODE_USE_BEDROCK: .env.CLAUDE_CODE_USE_BEDROCK,
    AWS_REGION: .env.AWS_REGION,
    ANTHROPIC_MODEL: $review_model,
    CLAUDE_CODE_MAX_OUTPUT_TOKENS: .env.CLAUDE_CODE_MAX_OUTPUT_TOKENS,
    MAX_THINKING_TOKENS: .env.MAX_THINKING_TOKENS
  },
  permissions: {
    allow: [
      "Read(~/**)", "Grep", "Glob", "WebSearch", "WebFetch", "Fetch",
      "Bash"
    ],
    deny: [
      "Edit(*)", "Write(*)",
      "Bash(codex exec:*)", "Bash(claude:*)",
      "Bash(git reset:*)", "Bash(git checkout:*)",
      "Bash(git clean:*)", "Bash(git push:*)",
      "Bash(rm:*)", "Bash(rmdir:*)", "Bash(mv:*)",
      "Bash(cp:*)", "Bash(mkdir:*)", "Bash(touch:*)",
      "Bash(chmod:*)", "Bash(chown:*)", "Bash(sudo:*)",
      "Bash(npx:*)", "Bash(pnpx:*)", "Bash(bunx:*)",
      "Bash(brew install:*)", "Bash(brew upgrade:*)",
      "Bash(brew uninstall:*)", "Bash(npm install:*)",
      "Bash(npm i:*)", "Bash(npm ci:*)",
      "Bash(pnpm install:*)", "Bash(yarn install:*)",
      "Bash(bun install:*)",
      "Bash(pip install:*)", "Bash(pip3 install:*)",
      "Bash(python -c:*)", "Bash(python3 -c:*)", "Bash(ruby -e:*)",
      "mcp__ais__*"
    ]
  },
  sandbox: {enabled: false}
}' "$CLAUDE_MAIN_SETTINGS")

env claude -p \
  --safe-mode \
  --settings "$CLAUDE_REVIEW_SETTINGS_JSON" \
  --model "$CLAUDE_REVIEW_MODEL" \
  --effort "$CLAUDE_REVIEW_EFFORT" \
  --permission-mode default \
  --tools "Read,Grep,Glob,WebSearch,WebFetch,Fetch,Bash" \
  --allowedTools "Read,Grep,Glob,WebSearch,WebFetch,Fetch,Bash" \
  --output-format stream-json \
  --include-partial-messages \
  --verbose \
  "このプランまたは差分をレビューして。レビュー用の許可設定では編集系ツールと危険な Bash を禁止しているので、テスト・build・format・install・生成・編集・mutation・deploy コマンドは実行せず、差分・設定・既存ログの読取を主材料に判断して。現行仕様確認に限って WebFetch を使ってよい。WebSearch/Fetch が利用可能なら使ってもよいが、利用不能なら WebFetch 可能な public primary sources を直接読むこと。公式 docs・release notes・standards・package registry・source repository など public primary sources を優先し、private code・secret・env 値・customer data・大きな local diff を検索クエリや取得 URL に貼らないで。不足する実行結果があれば質問して。別の claude -p、codex exec、mcp__ais、外部レビューコマンドは絶対に起動しないで。瑣末な点へのクソリプはしないで。致命的な点だけ指摘して。回答内容が現時点で out of date / deprecated になっていないかにも気をつけて。Web を使った場合は参照 URL と判断への使い方を短く添えて: $PLAN_OR_DIFF_REF" \
  | tee "$REVIEW_LOG"
```

Capture the session id from the final stream result:

```bash
jq -r 'select(.type == "result") | .session_id' "$REVIEW_LOG" | tail -n 1
```

## Resume Review Template

Use the same session for updated plan reviews:

```bash
set -o pipefail

REVIEW_LOG=${REVIEW_LOG:-review-result.jsonl}

env claude -p \
  --safe-mode \
  --settings "$CLAUDE_REVIEW_SETTINGS_JSON" \
  --model "$CLAUDE_REVIEW_MODEL" \
  --effort "$CLAUDE_REVIEW_EFFORT" \
  --permission-mode default \
  --tools "Read,Grep,Glob,WebSearch,WebFetch,Fetch,Bash" \
  --allowedTools "Read,Grep,Glob,WebSearch,WebFetch,Fetch,Bash" \
  --output-format stream-json \
  --include-partial-messages \
  --verbose \
  --resume "$SESSION_ID" \
  "前回の指摘を反映してプランまたは差分を更新した。もう一度レビューして。前回と同じ制約で、テスト・build・format・install・生成・編集・mutation・deploy・外部レビューコマンドは実行しないで。現行仕様確認に限って public primary sources への WebFetch は使ってよい。WebSearch/Fetch が利用可能なら使ってもよい。致命的な点だけ指摘して。新しく追加された問題がなければ、その旨を明示して: $PLAN_OR_DIFF_REF" \
  | tee "$REVIEW_LOG"
```

For non-interactive automation where progress visibility is irrelevant, `--output-format json` may be used instead of `stream-json`.

## Permission Caveats

- Claude Code `--permission-mode default` with broad Bash and a denylist is not the same security boundary as `codex exec --sandbox read-only`.
- This review mode is intentionally blacklist-based so current local CLI documentation can be inspected without one-off permission churn. Keep review prompts explicit that tests, builds, installs, generation, mutation, and deployment are forbidden.
- Treat the review as complete only when a final `type == "result"` stream event is returned and the command used the explicit minimal settings above.
- If the command runs without the explicit Fable model, without `--safe-mode`, or with the full normal `claude/settings.json`, treat it as `review incomplete`.
- If the stream `init` event does not list `WebFetch`, treat the review command as misconfigured and rerun with the default `--safe-mode --permission-mode default` template. If `WebSearch` or `Fetch` are absent but `WebFetch` is present, the review can proceed.
- If a denied tool appears in `permission_denials`, treat that denial as evidence the permission gate worked, not as a review failure.
- If the reviewer needs command output that was intentionally blocked, provide existing logs or run the command yourself outside this review gate when appropriate.

## Timeout Semantics

- Wait for the final `type == "result"` stream event before reporting success:
  - about 15s for trivial prompts
  - about 30-60s for light reviews
  - about 180s for normal review tasks
- If intermediate output is still arriving, keep waiting until the review ends.
- `review started but final result not yet returned` is not `review complete`.
- For a required review, if the final answer is missing, try at least one `--resume "$SESSION_ID"` or rerun.
- If the final answer still cannot be recovered, report `review incomplete` and ask the user how to proceed.
- Do not say a review passed unless the final review answer was obtained.

## Validation

- `--safe-mode`, `--settings <json>`, explicit Fable `--model`, default `--effort medium`, `--output-format stream-json --include-partial-messages --verbose`, and `--resume` were verified with Claude Code 2.1.197.
- The stream output ends with `type == "result"` and includes `.session_id` and `modelUsage."global.anthropic.claude-fable-5"`.
- In Claude Code 2.1.197, `--bare` and `--permission-mode plan` exposed only `Read`; `--safe-mode --permission-mode default` exposed `Bash`, `Glob`, `Grep`, `Read`, and `WebFetch`.
- A dry run attempting `Bash(claude -p hi)` returned a permission denial instead of executing.
- After editing this skill, run:

```bash
python3 /Users/lilpacy/dotfiles/codex/skills/.system/skill-creator/scripts/quick_validate.py /Users/lilpacy/dotfiles/skills/claude-fable-review
```
