---
description: codex CLIに直接質問する
context: fork
argument-hint: <質問内容>
allowed-tools:
  - mcp__codex__codex_exec
---

# Codex CLI

## Your task

ユーザーの依頼内容をもとに現状のコード、事象、試したこと、ゴールなど不足している文脈や言葉足らずな点を補って、 codex CLI に相談をして回答を得てください。

**質問内容**: $ARGUMENTS

## 実行手順

`mcp__codex__codex_exec` ツールを使い、prompt パラメータに質問内容を渡す。

### sandbox パラメータ

`sandbox` パラメータでCodexの実行権限を制御する。

| 値 | 用途 |
|---|---|
| `read-only`（デフォルト） | コード読解・設計・レビューなどインターネット不要のタスク |
| `workspace-write` | ワークスペースへの書き込みが必要なタスク |
| `danger-full-access` | **インターネットアクセスが必要なタスク**（Web検索を伴う推論など） |

**判定ルール**:
- 原則: `sandbox` を省略する（= `read-only`）
- 質問内容がWeb検索・外部API呼び出し・最新情報の取得を必要とする場合のみ `sandbox: "danger-full-access"` を明示指定する
- ファイル生成・編集をCodex側で行わせる必要がある場合は `sandbox: "workspace-write"` を指定する

## Constraints
- codex exec がエラーになった場合はエラー内容を伝えること

