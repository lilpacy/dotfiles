---
name: discuss
description: Claude×Codex 議論
allowed-tools: Bash(codex *)
context: fork
argument-hint: <テーマ>
---

# Claude×Codex 議論

テーマ: $ARGUMENTS

## 手順

1. Bashで `codex exec` を実行し、問いの本質定義のみを依頼する（立場はまだ出させない）
   - prompt: テーマ・背景文脈・思考原則・「問いの本質を1文で定義せよ」
   ```bash
   codex exec -s read-only --skip-git-repo-check "<prompt>"
   ```
2. CCがCodexの問い定義に基づき、独立して初期立場を生成する
   - この時点でCodexの立場は存在しないため、アンカリングは発生しない
3. Bashで `codex exec` を実行し、同じ問いへの独立した初期立場を生成させる
   - CCの立場は含めない（アンカリング防止）
4. Bashで `codex exec` を実行し、両立場を渡して批評・論点整理を依頼する（Codexが主導）
5. CCはCodexの批評に応答する
6. 合意点・相違点・修正案を毎ラリーで明示する
7. 完全合意までCodexが指揮しラリーを継続する。無理な妥協は禁止
8. 完全合意後、Bashで `codex exec` を実行し合意内容を構造化させる
9. CCがユーザーに合意結果を提示する

## codex exec 共通パラメータ

- sandbox: `-s read-only`（議論はインターネット不要）
- フラグ: `--skip-git-repo-check` 必須
- timeout: Bashツールで 600000 を指定

## アーカイブ保存

各ラリーのcodex exec結果をアーカイブ保存する:

```bash
DIR=~/.claude/codex-responses/$(date +%Y-%m-%d) && mkdir -p "$DIR"
# 議論結果をファイルに保存
```
