---
name: linear-issue-organizer
description: |
  Linearのissueを整理し、会話しながら新規issueに落とすスキル。2つのモードを持つ:
  (1) 既存issue整理: Backlogの全issueをINVEST原則で診断し、分割・統合・再分類を提案・実行
  (2) 会話→issue化: ユーザーとの対話から要件を引き出し、適切な粒度のissueに落とす
  両モード完了後、整理された実行計画を自動生成する。
  トリガー: 「issueを整理して」「Backlog整理」「issue棚卸し」「やること整理」「実行計画を作って」
  「issueの粒度を揃えて」「issueに落として」「要件をissueにして」
---

# Linear Issue Organizer

Linearのissueを整理し、会話から新規issueを生成し、整理された実行計画を出力する。

前提: linear-cli skillが利用可能であること。CLAUDE.mdのLinear-CLI Settingsを参照。

## ワークフロー

```
Phase 1: organize (既存issue整理)
Phase 2: capture (会話→issue化)
Phase 3: catalog (実行計画生成)
```

「整理して」→Phase 1から、「issueに落として」→Phase 2から、「実行計画」→Phase 3から。明示なければ1→2→3。

---

## Phase 1: organize

### Step 1: 全issue取得

```bash
linear issue list --team {TEAM_ID} --sort priority -s unstarted -A --no-pager
linear issue list --team {TEAM_ID} --sort priority -s started -A --no-pager
linear issue list --team {TEAM_ID} --sort priority -s backlog -A --no-pager
```

### Step 2: INVEST診断

各issueを6項目で判定:

| 原則 | 判定基準 |
|---|---|
| **I**ndependent | 単独で着手可能か |
| **N**egotiable | アウトカムで記述されているか（実装手段でなく） |
| **V**aluable | 完了時に明確な価値があるか |
| **E**stimable | 1〜3日と見積もれるか |
| **S**mall | 1〜3日で完了できるか |
| **T**estable | pass/failで判定可能か |

### Step 3: 問題issueを分類

- **課題→Project昇格**: 完了条件がない抽象的な課題
- **分割が必要**: 複数の関心事が混在 → 縦割りスライスで分解
- **型の変更**: Spike(調査)とFeature/Taskが混在 → 分離
- **統合が必要**: 細かすぎるissueが散在
- **OK**: 変更不要

### Step 4: 提案

テーブルで提示し、ユーザー承認を得る:

```
| ID | タイトル | 診断 | 提案 |
|---|---|---|---|
| XXX-01 | ... | I❌ S❌ | → 3分割: Spike + Task + Feature |
| XXX-02 | ... | N❌ V❌ | → Project昇格 |
| XXX-03 | ... | 全✅ | 変更なし |
```

### Step 5: 実行

承認後にlinear CLIで反映:
- 分割: 新issue作成 + 元issueクローズ
- Project昇格: `linear project create` + issue移動
- 型変更: ラベル変更 + タイトル修正（動詞始まり）
- 統合: 1つに集約し他をクローズ

### 分割時のルール

**縦割りスライス**で分割する。横割り（DB→API→UI→テスト）ではなく、ユーザー価値単位で縦に切る。

**Issue型の使い分け:**

| Type | 定義 | サイズ |
|---|---|---|
| Feature | ユーザー価値を提供する機能追加 | 1〜3日 |
| Task | 明確なステップの実行 | 0.5〜1日 |
| Bug | 既存機能の不具合修正 | 0.5〜2日 |
| Spike | 不確実性の解消（time-boxed） | 0.5〜1日 |

**SpikeとFeature/Taskは必ず分離。** Spikeの結果を受けてTask/Featureが生まれる。

---

## Phase 2: capture

### Step 1: ヒアリング

一度に2問まで:

1. 「今やりたいこと・気になっていることは？」
2. 具体的な機能が出たら「それは誰がどう使えるようになるイメージ？」

### Step 2: issue候補を生成

ルール:
- タイトルは**動詞で始める**
- 1 issue = 1アウトカム
- 型を明示: Feature / Task / Bug / Spike
- サイズ: 1〜3日。超えるなら分割
- 不確実性が高い → Spike + 後続issueに分離

### Step 3: 依存関係を整理

issue間の依存を明示し、critical pathを提示:

```
Spike → Task → Feature群（並列可能）
```

### Step 4: Linearに投入

ユーザー確認後、linear CLIで一括作成。依存関係はdescription内に`Blocked by: XXX-NN`で明記。

---

## Phase 3: catalog

Phase 1・2完了後、全issueを再取得し実行計画を出力。

### 出力形式

```markdown
# 実行計画 ({プロジェクト名}) - {日付}

## 実行予定

### {Project名 or カテゴリ}

| # | Issue | Type | Size | 依存 | Status |
|---|---|---|---|---|---|
| 1 | XXX-01: 〜を調査する | Spike | 0.5日 | - | Todo |
| 2 | XXX-02: 〜を追加する | Task | 0.5日 | #1 | Todo |
| 3 | XXX-03: 〜を表示する | Feature | 1日 | #2 | Todo |

## Parking Lot (保留)

| Issue | 理由 |
|---|---|
| XXX-99: ... | スコープ未定 |
```

### 出力ルール

- Projectごとにグループ化（未所属は「未分類」）
- 依存関係順（topological sort）でソート
- completed/canceledは除外
- Size: 0.5日 / 1日 / 1〜2日 / 2〜3日
- 要望があればMarkdownファイルとして保存
