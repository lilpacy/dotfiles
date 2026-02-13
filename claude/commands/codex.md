---
description: codex CLIに直接質問する
context: fork
argument-hint: <質問内容>
allowed-tools:
  - mcp__codex__codex_exec
---

# Codex CLI

## Your task

ユーザーの質問を codex CLI に渡して回答を得てください。

**質問内容**: $ARGUMENTS

## 実行手順

`mcp__codex__codex_exec` ツールを使い、prompt パラメータに質問内容を渡す。

## Constraints
- codex の出力をそのまま伝えること（要約や改変しない）
- codex exec がエラーになった場合はエラー内容を伝えること
