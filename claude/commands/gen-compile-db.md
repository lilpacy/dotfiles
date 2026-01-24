---
description: clangd用のcompile_commands.jsonを生成する（compiledb推奨、bearも対応）
allowed-tools:
  - Bash(compiledb*:*)
  - Bash(make clean:*)
  - Bash(bear -- make*:*)
  - Bash(ls -la compile_commands.json:*)
  - Bash(grep*compile_commands.json:*)
---

# Generate compile_commands.json for clangd

## Your task
C言語プロジェクトでclangdが正しく動作するよう、`compile_commands.json`を生成する。

## Method selection

### 推奨: compiledb（ドライラン方式）
- 再ビルド不要で高速
- 再帰的Makeに対応（`make -C subdir`も自動処理）
- サブディレクトリのライブラリ（libftなど）も含めて1コマンドで完結

### 代替: bear（実ビルド方式）
- compiledbが使えない環境
- ただし、サブディレクトリが既にビルド済みの場合はキャプチャ漏れが発生する可能性あり

## Steps

### 1. Makefileの存在確認
- カレントディレクトリにMakefileがあることを確認
- Makefileがない場合はエラーを報告して終了

### 2. compiledbを試す（推奨）
```bash
compiledb -n make all
```

- compiledbがインストールされていない場合は `pip install compiledb` を案内
- 成功した場合は3へ

### 3. bearにフォールバック（compiledb未インストール時）
```bash
make clean
bear -- make
```

- bearがインストールされていない場合は `brew install bear` を案内
- **注意**: サブディレクトリのMakefile（libftなど）が既にビルド済みの場合、`bear -- make -B` で強制リビルドが必要

### 4. 生成確認と報告
- `compile_commands.json` の存在を確認
- ファイルサイズとエントリ数を報告
- サブディレクトリのファイルが含まれているか確認（プロジェクト構造に応じて）

## Output
- 使用した方法（compiledb or bear）
- 実行結果のサマリー
- compile_commands.json が生成されたかどうか
- エントリ数とカバレッジ情報（可能であれば）
