---
description: git diffを指定した観点でレビューする
context: fork
model: opus
argument-hint: <観点: react, security, performance, etc.>
allowed-tools:
  - Bash(git diff*)
---

# Diff Review

## Context
```
!git diff
```

## Your task
上記の git diff の内容を、ユーザーが指定した観点でレビューしてください。

**指定された観点**: $ARGUMENTS

### 該当Skillの活用（重要）
指定された観点に該当するClaude Code Skillがある場合は、**Skill toolを使って該当スキルを発動し**、そのスキルの専門知識を活用してレビューすること。

例:
- `react` / `frontend` → `react-best-practices` スキルを発動
- `nextjs` / `app-router` → `nextjs-app-router-guide` スキルを発動

### 観点の解釈ガイド
引数に応じて適切な観点を選択してください：

| キーワード例 | レビュー観点 | 関連Skill |
|-------------|-------------|-----------|
| react, frontend | Reactベストプラクティス、コンポーネント設計 | react-best-practices |
| nextjs, app-router | Next.js App Router、Server Components | nextjs-app-router-guide |
| security | セキュリティ脆弱性、入力検証、認証認可 | - |
| performance, perf | パフォーマンス、N+1、メモリリーク | - |
| typescript, ts | 型安全性、any回避、型設計 | - |
| test | テストカバレッジ、エッジケース、モック設計 | - |
| (空/未指定) | 汎用コードレビュー（可読性、保守性、バグリスク） | - |

## Constraints
- ファイル編集は禁止。レビューコメントのみを出力すること
- 指摘は具体的に（該当行や該当コードを示す）
- 重要度を明示する（🔴 Critical / 🟡 Warning / 🔵 Info）

## Output format
```markdown
## レビュー結果: <観点>

### 🔴 Critical
- ...

### 🟡 Warning
- ...

### 🔵 Info / 提案
- ...

### ✅ Good points
- ...
```
