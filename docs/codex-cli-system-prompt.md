# Codex CLI システムプロンプトの配置方法

## 概要

Codex CLI には `CLAUDE.md` に相当する単一のグローバル instructions ファイルは存在しない。
代わりに3つの仕組みで構成される。

## 1. `AGENTS.md`（プロジェクトレベル）

- **場所**: プロジェクトルート（または任意のサブディレクトリ）
- **用途**: プロジェクト固有のコーディング規約・構造・指示
- **スコープ**: 配置ディレクトリ配下のツリー全体に適用
- Codex CLI 起動時に自動的に読み込まれる

## 2. `~/.codex/config.toml`（グローバル設定）

- **用途**: モデル選択、personality、プロジェクトごとの trust level
- `personality` は `"pragmatic"` / `"friendly"` の2択のみ。自由文でのシステムプロンプト注入は不可

```toml
model = "gpt-5-codex"
model_reasoning_effort = "high"
personality = "pragmatic"

[projects."/path/to/project"]
trust_level = "trusted"
```

## 3. `~/.codex/skills/`（再利用可能なスキル）

- 各スキルディレクトリに `SKILL.md` を配置する形式
- セッション開始時にスキルのメタデータが読み込まれる

## Claude Code との対比

| 機能 | Claude Code | Codex CLI |
|---|---|---|
| グローバル指示 | `~/.claude/CLAUDE.md` | **該当なし**（config.toml のみ） |
| プロジェクト指示 | プロジェクトの `CLAUDE.md` | プロジェクトの `AGENTS.md` |
| スキル | `~/.claude/skills/` | `~/.codex/skills/` |

## 結論

Codex CLI でグローバルなカスタムシステムプロンプトを自由記述で入れる方法は現状ない。
プロジェクト単位なら `AGENTS.md` に書くのが正解。
