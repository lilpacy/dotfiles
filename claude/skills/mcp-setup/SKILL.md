# MCP Setup

Claude Code に MCP サーバーを実際にセットアップ（追加・削除・一覧・確認）するSkill。
「MCPを追加して」「〜のMCPを入れて」「MCP設定して」「MCPサーバーを追加」「MCP一覧」「MCPを削除」
「claude mcp add」「MCP入れたい」「〜をMCPで使いたい」などの依頼で発動する。
ガイドではなく、実際にコマンドを実行して設定を完了させる。

## Goals
- ユーザーの依頼に基づき、正しい `claude mcp add` / `add-json` コマンドを組み立て、**実行**する
- 必要な情報（サーバー名・URL・トークン・transport等）が不足していれば質問する
- 追加後に `claude mcp get <name>` で設定を確認し、結果を報告する

## Non-goals
- MCPサーバー自体の開発やデバッグ
- MCPプロトコルの仕様解説（聞かれたら簡潔に答える程度）

## Inputs
- ユーザーからの自然言語での依頼（例:「filesystem MCPを入れて」「Supabase MCPを追加して」）
- 必要に応じて: URL、APIキー、npm パッケージ名、環境変数

## Outputs
- 実行したコマンドとその結果
- 設定確認（`claude mcp get` の出力）

## Instructions

### 1. 依頼内容を判定する

操作の種類を特定する：

| 操作 | コマンド |
|------|---------|
| 追加 | `claude mcp add` / `claude mcp add-json` |
| 一覧 | `claude mcp list` |
| 詳細 | `claude mcp get <name>` |
| 削除 | `claude mcp remove <name>` |
| Desktop からインポート | `claude mcp add-from-claude-desktop` |
| 承認リセット | `claude mcp reset-project-choices` |

### 2. 追加の場合、transport を決める

| transport | 用途 | 例 |
|-----------|------|-----|
| `http` | リモートHTTPサーバー（推奨） | SaaS API、リモートMCPエンドポイント |
| `sse` | リモートSSE（非推奨） | レガシーSSEサーバー |
| `stdio` | ローカルプロセス起動 | `npx -y @package/name`、ローカルバイナリ |

### 3. コマンドを組み立てる

#### HTTP サーバー
```bash
claude mcp add --transport http <name> <url>
# ヘッダー付き
claude mcp add --transport http <name> <url> \
  --header "Authorization: Bearer <token>"
```

#### stdio サーバー（npx等）
```bash
claude mcp add --transport stdio <name> -- npx -y <package>
# 環境変数付き
claude mcp add --transport stdio --env API_KEY=xxx <name> -- npx -y <package>
```

#### JSON で追加（複雑な設定）
```bash
claude mcp add-json <name> '<json>'
```

**オプション順序の鉄則**: `--transport`, `--env`, `--scope`, `--header` は必ず `<name>` より前に置く。

### 4. scope を決める

- `local`（デフォルト）: 現在のプロジェクトの現ユーザーのみ
- `project`: `.mcp.json` に保存、チーム共有
- `user`: `~/.claude.json` に保存、全プロジェクト共通

ユーザーが指定しなければ `user` をデフォルトとして提案する（MCPサーバーは通常プロジェクト横断で使うため）。

### 5. 実行して確認する

1. コマンドを実行する
2. `claude mcp get <name>` で設定内容を確認する
3. 結果をユーザーに報告する

### 6. OAuth認証が必要な場合

```bash
claude mcp add --transport http \
  --client-id <client-id> --client-secret --callback-port 8080 \
  <name> <url>
```

追加後、Claude Code 内で `/mcp` を実行して認証フローを開始するよう案内する。

## Quality Checklist
- [ ] transport の選択が正しい（HTTP / stdio / SSE）
- [ ] オプション順序が正しい（`--transport`, `--env` 等は `<name>` の前）
- [ ] stdio の場合 `--` の後にコマンドが来ている
- [ ] scope が適切（ユーザーに確認 or 合理的なデフォルト）
- [ ] 実行後に `claude mcp get` で確認している
- [ ] APIキー等の機密情報をログに残していない

## Examples

### Example 1: 追加
ユーザー: 「filesystem MCPを入れて」
→ `claude mcp add --transport stdio --scope user filesystem -- npx -y @anthropic/mcp-filesystem` を実行

### Example 2: 追加（HTTP）
ユーザー: 「weather APIのMCPを追加して、URLはhttps://example.com/mcp」
→ `claude mcp add --transport http --scope user weather-api https://example.com/mcp` を実行

### Example 3: 一覧
ユーザー: 「今入ってるMCP見せて」
→ `claude mcp list` を実行

### Example 4: 削除
ユーザー: 「weather-api MCP消して」
→ `claude mcp remove weather-api` を実行

### Example 5: Desktop からインポート
ユーザー: 「Claude DesktopのMCP設定を持ってきて」
→ `claude mcp add-from-claude-desktop` を実行
