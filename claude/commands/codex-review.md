---
description: codex CLIを使ってコードをレビューする
context: fork
argument-hint: <diff target or file/folder path>
allowed-tools:
  - Bash(git diff*)
  - Bash(git ls-files*)
  - Bash(git rev-parse*)
  - Bash(find *)
  - Bash(test *)
  - Bash(cat *)
  - mcp__codex__codex_exec
---

# Codex Code Review

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

- `/codex-review` → 現在の変更（staged + unstaged + untracked）をレビュー
- `/codex-review HEAD~3` → 直近3コミットのdiffをレビュー
- `/codex-review main..feature` → ブランチ間のdiffをレビュー
- `/codex-review main -- src/utils.ts` → 特定ファイルのdiffをレビュー
- `/codex-review src/utils.ts` → ファイルの中身全体をレビュー
- `/codex-review src/` → フォルダ配下のコードをレビュー

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

## 実行手順

### diffモード

1. diff内容を取得:
   - 引数が空の場合: 上記 Context セクションで取得済みの diff を使用
   - 引数がある場合: `git diff $ARGUMENTS` を実行
2. `mcp__codex__codex_exec` ツールを呼び出し、prompt に以下を渡す:

```
以下のgit diffをコードレビューしてください。バグ、セキュリティ問題、パフォーマンス問題、可読性の観点でレビューし、重要度（Critical/Warning/Info）を付けて指摘してください。良い点も挙げてください。

（diff内容をここに埋め込む）
```

### ファイルレビューモード

1. 引数の各パスについて:
   - ファイルの場合: `cat` で内容を取得
   - ディレクトリの場合: `find <dir> -type f` で再帰的にファイル一覧を取得し、各ファイルを `cat`
2. `mcp__codex__codex_exec` ツールを呼び出し、prompt に以下を渡す:

```
以下のコードをレビューしてください。バグ、セキュリティ問題、パフォーマンス問題、可読性の観点でレビューし、重要度（Critical/Warning/Info）を付けて指摘してください。良い点も挙げてください。

=== FILE: path/to/file1.ts ===
（ファイル内容）

=== FILE: path/to/file2.ts ===
（ファイル内容）
```

## sandbox

コードレビューはインターネットアクセス不要のため、`sandbox` パラメータは省略する（= `read-only`）。

## Constraints
- ファイル編集は禁止。レビュー結果の表示のみ
- codex exec の出力をそのまま伝えること（要約や改変しない）
- codex exec がエラーになった場合はエラー内容を伝えること
