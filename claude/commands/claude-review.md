---
description: Claude自身がコードをレビューする
context: fork
model: opus
argument-hint: <diff target or file/folder path>
allowed-tools:
  - Bash(git diff*)
  - Bash(git ls-files*)
  - Bash(git rev-parse*)
  - Bash(find *)
  - Bash(test *)
  - Bash(cat *)
---

# Claude Code Review

## Context

### Staged & Unstaged changes
```
!git diff HEAD
```

### Untracked files
```
!git ls-files --others --exclude-standard | while read f; do echo "=== NEW FILE: $f ==="; cat "$f"; done
```

## 使い方

- `/claude-review` → 現在の変更（staged + unstaged + untracked）をレビュー
- `/claude-review HEAD~3` → 直近3コミットのdiffをレビュー
- `/claude-review main..feature` → ブランチ間のdiffをレビュー
- `/claude-review main -- src/utils.ts` → 特定ファイルのdiffをレビュー
- `/claude-review src/utils.ts` → ファイルの中身全体をレビュー
- `/claude-review src/` → フォルダ配下のコードをレビュー

## Your task

**引数**: $ARGUMENTS

### モード判定

引数の内容に応じて **diffモード** か **ファイルレビューモード** を自動判定してください。

**判定ルール**:
1. 引数が空 → **diffモード**（上記 Context セクションの diff を使用）
2. 引数の各トークンを順にチェックし、以下のいずれかに該当するものが**1つでも**あれば → **diffモード**:
   - `..` または `...` を含む（例: `main..feature`）
   - `--staged`, `--cached`, `--stat` 等の git diff オプション
   - `--` トークン（パスとの境界）
   - `git rev-parse --verify "$token^{commit}"` でコミットとして解決できる（例: `HEAD`, `HEAD~3`, `main`, ブランチ名）
3. 上記に該当するトークンが1つもない → **ファイルレビューモード**

### diffモード

- 引数が空の場合: 上記 Context セクションで取得済みの diff を使用
- 引数がある場合: `git diff $ARGUMENTS` を実行してその結果をレビュー

### ファイルレビューモード

引数の各パスについて:
- ファイルの場合: `cat` で内容を取得してレビュー
- ディレクトリの場合: `find <dir> -type f` で再帰的にファイル一覧を取得し、各ファイルを読み取ってレビュー

## レビュー観点
バグ、セキュリティ問題、パフォーマンス問題、可読性の全観点でレビューすること。

### Skillの活用
レビュー対象に該当するClaude Code Skillがある場合は、Skill toolで発動して専門知識を活用すること。
例: React コード → `react-best-practices` / Next.js → `nextjs-app-router-guide`

## Constraints
- ファイル編集は禁止。レビューコメントのみを出力すること
- 指摘は具体的に（該当行や該当コードを示す）
- 重要度を明示する（🔴 Critical / 🟡 Warning / 🔵 Info）

## Output format
```markdown
## レビュー結果

### 🔴 Critical
- ...

### 🟡 Warning
- ...

### 🔵 Info / 提案
- ...

### ✅ Good points
- ...
```
