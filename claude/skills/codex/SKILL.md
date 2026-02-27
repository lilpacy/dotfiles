---
name: codex
description: codex CLIに直接質問する
allowed-tools: Bash(codex *)
context: fork
argument-hint: <質問内容>
---

# Codex CLI

## Your task

ユーザーの依頼内容をもとに現状のコード、事象、試したこと、ゴールなど不足している文脈や言葉足らずな点を補って、 codex CLI に相談をして回答を得てください。

**質問内容**: $ARGUMENTS

## 実行手順

### Step 1: codex exec 実行

Bashツールで以下を実行する（timeout: 600000）:

```bash
codex exec -s <sandbox> --skip-git-repo-check "<prompt>"
```

- `--skip-git-repo-check` は必須
- プロンプトが長い場合は一時ファイル経由でもよい

### Step 2: アーカイブ保存

実行結果を取得したら、別のBash呼び出しでアーカイブ保存する:

```bash
DIR=~/.claude/codex-responses/$(date +%Y-%m-%d) && mkdir -p "$DIR"
cat > "$DIR/$(date +%H-%M-%S)_$RANDOM.md" << 'EOF'
# Codex Response
- Sandbox: <sandbox>
- Timestamp: <timestamp>

## Prompt
<prompt>

## Response
<response>
EOF
```

### Step 3: 結果表示

codex exec の出力をユーザーにそのまま伝える。

## sandbox判定ルール

| 値 | 用途 |
|---|---|
| `read-only`（デフォルト） | コード読解・設計・レビューなどインターネット不要のタスク |
| `workspace-write` | ワークスペースへの書き込みが必要なタスク |
| `danger-full-access` | **インターネットアクセスが必要なタスク**（Web検索を伴う推論など） |

**判定ルール**:
- 原則: `-s read-only`（sandbox省略不可、明示指定する）
- 質問内容がWeb検索・外部API・最新情報取得を必要とする場合のみ `-s danger-full-access`
- ファイル生成・編集をCodex側で行わせる必要がある場合のみ `-s workspace-write`

### model指定

ユーザーがモデルを指定した場合のみ `-m` オプションを追加:
モデルを選択する必要がある場合には、設計・レビューは高価なモデル、実装はコスト効率のいいモデルを基本的に使う。
```bash
codex exec -s read-only --skip-git-repo-check -m gpt-5.2-codex "<prompt>"
```

## 大きな出力の処理

codex exec の結果がトークン上限を超えてファイルに保存された場合（`Output has been saved to ...` メッセージ）:

- 結果はJSON配列 `[{type, text}]` 形式。codexの最終回答は**配列の最後の要素のtext末尾**にある
- 探索的にGrep/Read/tailを繰り返すのは非効率。以下のワンライナーで末尾を直接抽出する:

```bash
python3 -c "
import json
with open('<保存先パス>') as f:
    data = json.load(f)
for item in data:
    t = item.get('text','')
    if t:
        print(t[-3000:])
"
```

## Constraints

- codex exec がエラーになった場合はエラー内容をユーザーに伝えること
