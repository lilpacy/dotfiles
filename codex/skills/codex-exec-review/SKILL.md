---
name: codex-exec-review
description: Use before presenting implementation plans and after non-trivial commits that require review. Runs codex exec in read-only review mode, handles resume, MCP transport errors, and review timeout semantics.
---

# Codex Exec Review

## Required Gates

- Before presenting an implementation plan to the user, run `codex exec` to review the plan.
- After a non-trivial commit, run `codex exec` to review the committed change.
- Repeat review up to 3 times. Stop when no critical issue remains.
- Do not replace a required review with local tests or your own judgment.

## Review Command Rules

- Use `--sandbox read-only`.
- Use `-c model_reasoning_effort=medium` only for review runs.
- Use `-c service_tier=fast` and `-c features.fast_mode=true` when appropriate.
- Add `--skip-git-repo-check` only when the review must run outside a Git repository.
- Instruct the reviewer not to run tests, build, format, install, or generation commands.
- Instruct the reviewer to judge from diffs, configuration, and existing logs only, and to ask if execution results are missing.
- Instruct the reviewer not to start another `codex exec` or external review command.
- Instruct the reviewer to report only critical issues, and to check whether the answer is out of date or deprecated.

## Initial Review Template

```bash
codex exec \
  --sandbox read-only \
  --model gpt-5.4 \
  -c model_reasoning_effort=medium \
  -c service_tier=fast \
  -c features.fast_mode=true \
  "このプランをレビューして。read-only sandboxなのでテスト・build・format・install・生成コマンドは実行せず、差分・設定・既存ログの読取だけで判断して。不足する実行結果があれば質問して。別の codex exec や外部レビューコマンドは絶対に起動しないで。瑣末な点へのクソリプはしないで。致命的な点だけ指摘して。回答内容が現時点で out of date / deprecated になっていないかにも気をつけて: {plan_full_path} (ref: {CLAUDE_md_full_path})"
```

## Resume Review Template

Use the same session for updated plan reviews:

```bash
codex exec resume <SESSION_ID> \
  "前回の指摘を反映してプランを更新した。もう一度レビューして。read-only sandboxなのでテスト・build・format・install・生成コマンドは実行せず、差分・設定・既存ログの読取だけで判断して。不足する実行結果があれば質問して。別の codex exec や外部レビューコマンドは絶対に起動しないで。瑣末な点へのクソリプはしないで。致命的な点だけ指摘して。新しく追加された問題がなければ、その旨を明示して: {plan_full_path} (ref: {CLAUDE_md_full_path})"
```

## MCP Transport Errors

- `codex exec` may print MCP transport errors such as `http://127.0.0.1:8000/mcp` connection failures at startup.
- Do not treat those logs alone as a `codex exec` failure.
- If a final `codex` response is returned after the error, consider the run successful but degraded.
- Treat the run as failed only when `codex exec` exits without a final `codex` answer or without the requested review result.
- Report MCP sidecar or transport failure separately from actual `codex exec` failure.

## Timeout Semantics

- Wait for the final answer before reporting failure:
  - about 15s for trivial prompts
  - about 30-60s for light reviews
  - about 180s for normal review tasks
- If intermediate output is still arriving, keep waiting until the review ends.
- `review started but final result not yet returned` is not `review complete`.
- For a required review, if the final answer is missing, try at least one `codex exec resume <SESSION_ID>` or rerun.
- If the final answer still cannot be recovered, report `review incomplete` and ask the user how to proceed.
- Do not say a review passed unless the final review answer was obtained.
