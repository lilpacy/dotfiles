---
description: clangd用のcompile_commands.jsonを生成する（bear + make）
allowed-tools:
  - Bash(make clean:*)
  - Bash(bear -- make:*)
---

# Generate compile_commands.json for clangd

## Your task
C言語プロジェクトでclangdが正しく動作するよう、`compile_commands.json`を生成する。

## Steps
1. `make clean` でビルド成果物をクリーンアップ
2. `bear -- make` でビルドしながら `compile_commands.json` を生成
3. 生成されたファイルの存在を確認して報告

## Constraints
- カレントディレクトリにMakefileがあることを前提とする
- Makefileがない場合はエラーを報告して終了
- bearがインストールされていない場合は `brew install bear` を案内

## Output
- 実行結果のサマリー
- compile_commands.json が生成されたかどうか
