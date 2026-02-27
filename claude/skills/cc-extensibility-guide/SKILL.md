---
name: cc-extensibility-guide
description: >
  Claude Codeの拡張機構（CLAUDE.md / Skills / MCP）の使い分けガイド。
  「CLAUDE.mdに書くべき？skillにすべき？」「MCPとskillの違いは？」「拡張したいけどどれで作る？」
  「.claude/commandsと.claude/skillsの違い」「MCP serverはいつ使う？」
  「常時適用ルールはどこに書く？」「コンテキスト効率を上げたい」などの判断に使う。
  Claude Code自体の拡張設計の相談・レビュー時にも自動検出される。
---

# Claude Code 拡張機構の使い分け

## 3層モデル

```
CLAUDE.md（基盤知識層・常時読み込み）
  → Skills/Commands（手順・タスク層・オンデマンド）
    → MCP（外部接続層・ステートフル通信）
```

- **CLAUDE.md** = 憲法（全セッションで常に適用されるルール・知識）
- **Skills** = 手順書・専門知識（特定の作業文脈でオンデマンド読み込み）
- **MCP** = 手足（外部サービスとのステートフル通信）
- **Commands** = Skillsの旧形式（後方互換で動作するが新規作成は非推奨）

## CLAUDE.md vs Skills の境界

ここが最も混乱しやすいポイント。どちらも「Claudeに知識を与える」点は同じ。

- **CLAUDE.md** = 全セッション・全作業で常に適用したいルール。「pnpmを使う」「テストはvitest」「Linear issueのステータス遷移フロー」など。
- **Skill（知識型）** = 特定の作業文脈でのみ必要な知識。「Figmaデザインの実装手順」「記事執筆のスタイルガイド」など。

CLAUDE.mdにあらゆる知識を詰め込むとコンテキストを無駄に消費する。特定場面でしか使わない知識はSkillに分離する。

CLAUDE.mdが大きくなったら `.claude/rules/*.md` でトピック別に分割可能（`paths` frontmatterで適用範囲も絞れる）。

## 機能比較

| 機能 | CLAUDE.md | Skills | MCP |
|:-----|:---------:|:------:|:---:|
| 常時読み込み | o | x（オンデマンド） | x（ツール定義のみ常時） |
| 手動呼び出し (`/name`) | x | o | x |
| Claude自動検出・呼び出し | 不要（常時） | o | o（ツールとして） |
| 支援ファイル (templates等) | x（rules/で分割のみ） | o | x |
| サブエージェント実行 (`context: fork`) | x | o | x |
| 外部API/DB/サービス通信 | x | x | o |
| ステートフル接続 | x | x | o |
| 認証 (OAuth等) | x | x | o |

## 選択フロー

```
常に適用したいルール？ → Yes → CLAUDE.md / rules
  ↓ No
外部通信が必要？ → Yes → MCP Server
  ↓ No
複数参照ファイル or 自動検出 or サブエージェント分離？ → Yes → Skill
  ↓ No
新規作成？ → Skill（Commandsより常にSkillを選ぶ）
既存Commands？ → そのまま動く。移行は必要になった時でよい
```

## 組み合わせパターン

3層は排他ではなく補完関係。

| ユースケース | CLAUDE.md | Skill | MCP |
|:-------------|:----------|:------|:----|
| Figmaデザイン実装 | React規約・命名規則 | `/implement-design`（変換手順） | `figma-remote-mcp`（API） |
| コードレビュー+コミット | テスト方針・lint設定 | `/claude-review`（レビュー観点） | 不要 |
| 画像生成 | — | `/nanobanana-prompt-writer`（プロンプト知識） | `nanobanana`（Gemini API） |

## 判断の要約

| 状況 | 選択 |
|:-----|:-----|
| 全セッションで常に適用したいルール・知識 | CLAUDE.md |
| 外部サービスとの通信が必要 | MCP |
| 特定の作業文脈での知識・手順 + 自動検出 | Skill |
| 単純な定型手順（既存） | Command（そのまま） |
| 新規作成 | 常にSkill |
