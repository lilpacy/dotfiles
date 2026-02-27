---
name: linear-promote-to-project
description: >
  Linear IssueをProjectに昇格する。「〜をProjectに昇格して」「〜をProject化して」「Issue to Project」
  「このIssueをProjectにして」などで発動。指定IssueからProject作成、Sub-issueのProject紐付け、
  必要に応じてSub-issueの独立Issue化を実行する。linear CLIを使用。前提: linear-cli skillが必要。
---

# Linear Issue → Project 昇格

Issue + Sub-issueベースの運用で、スコープが膨らんだIssueをProjectに昇格する。

## 昇格判定基準

以下のうち2つ以上に該当する場合にProjectへの昇格を推奨する:

- 完了まで1週間以上かかる
- Sub-issueが5つ以上に膨らんだ
- 仕様やマイルストーンが必要
- ロードマップから見えるべき仕事

## 昇格手順

### Step 1: 対象Issueの情報取得

```bash
linear issue show <ISSUE_ID>
```

Issue のタイトル・説明・状態を確認する。

### Step 2: Sub-issue一覧取得

linear CLIにSub-issue一覧コマンドがないため、GraphQL APIで取得する:

```bash
linear api --variable identifier=<ISSUE_ID> <<'GRAPHQL'
query($identifier: String!) {
  issueSearch(filter: { parent: { identifier: { eq: $identifier } } }, first: 50) {
    nodes { id identifier title state { name } }
  }
}
GRAPHQL
```

### Step 3: Project作成

```bash
linear project create --name "<Issueタイトルをベースにしたプロジェクト名>" --state planned
```

### Step 4: Issue群をProjectに紐付け

親Issueと全Sub-issueをProjectに紐付ける:

```bash
# 親Issue
linear issue update <ISSUE_ID> --project "<プロジェクト名>"

# 各Sub-issue
linear issue update <SUB_ISSUE_ID> --project "<プロジェクト名>"
```

### Step 5: （オプション）Sub-issueを独立Issueに昇格

Sub-issueがそれぞれ独立した作業単位の場合、親子関係を解除する:

```bash
linear issue update <SUB_ISSUE_ID> --parent ""
```

### Step 6: 完了報告

昇格結果をユーザーに報告する。以下を含める:

- 作成したProject名とURL
- 紐付けたIssue数
- 独立化したSub-issue（あれば）

## 注意事項

- Project名はIssueタイトルをそのまま使うか、ユーザーに確認する
- Sub-issueの独立化はデフォルトでは行わない。ユーザーが明示的に求めた場合のみ実行する
- `linear project create` の `--state` は `planned`, `started`, `paused`, `completed`, `canceled` から選択。通常は `planned` で作成する

