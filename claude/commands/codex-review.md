---
description: codex CLIを使ってgit diffをレビューする
context: fork
argument-hint: <diff target: HEAD~3, main..feature, etc.>
allowed-tools:
  - Bash(git diff*)
  - Bash(git ls-files*)
  - Bash(codex*)
  - Bash(cat /tmp/codex-review*)
  - Bash(rm /tmp/codex-review*)
---

# Codex Diff Review

## Context

### Staged & Unstaged changes
```
!git diff HEAD
```

### Untracked files
```
!git ls-files --others --exclude-standard | while read f; do echo "=== NEW FILE: $f ==="; cat "$f"; done
```

## Your task

上記の git diff の内容を、OpenAI Codex CLI (`codex exec`) に渡してコードレビューさせてください。

**diff対象の指定**: $ARGUMENTS
- 引数が指定されている場合は、`git diff $ARGUMENTS` を改めて実行してそのdiffを使うこと
- 引数が空の場合は、上記の Context セクションで取得済みの diff を使うこと

## 実行手順

1. diff内容を一時ファイル `/tmp/codex-review-diff.patch` に書き出す
2. 以下のコマンドで codex exec を実行する:

```bash
codex exec -s read-only "以下のgit diffをコードレビューしてください。バグ、セキュリティ問題、パフォーマンス問題、可読性の観点でレビューし、重要度（Critical/Warning/Info）を付けて指摘してください。良い点も挙げてください。

$(cat /tmp/codex-review-diff.patch)"
```

3. codex の出力をそのままユーザーに表示する
4. 一時ファイルを削除する: `rm /tmp/codex-review-diff.patch`

## Constraints
- ファイル編集は禁止。レビュー結果の表示のみ
- codex exec の出力をそのまま伝えること（要約や改変しない）
- codex exec がエラーになった場合はエラー内容を伝えること
