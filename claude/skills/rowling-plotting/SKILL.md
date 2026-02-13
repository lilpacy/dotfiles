---
name: rowling-plotting
description: |
  J.K.ローリングの手描きプロット表（章×筋ストランド）を再現し、
  長編・シリーズ作品のストーリー構造を設計・点検するためのSkill。
  「複数のサブプロットを同時進行で管理したい」「伏線の置き忘れを防ぎたい」
  「章ごとの密度や停滞を可視化したい」時に使う。
  データはYAML（構造）+Markdown（思考メモ）で永続化し、Git管理できる。
---

# Rowling-Style Story Plotting Skill

## Purpose

このSkillは、J.K.ローリングが『ハリー・ポッター』第5巻で用いた
**「章 × 複数ストランド（筋）」のプロット表運用**を、
Claude Code 上で再現・支援するためのものです。

特徴：
- **終点（結末）を先に固定し、経路は可変**
- **章単位で、複数の物語ラインを並走管理**
- **伏線・ミスリード・回収を表で可視化**
- **YAML＝構造データ、Markdown＝思考メモの二層永続化**

---

## Core Concepts

### 1. ストランド（Strand）とは？

ストランドとは「物語の中で並行して進む意味のある筋」です。

例：
- メインプロット（事件・目的）
- 恋愛／人間関係
- 組織・勢力（学校、騎士団、会社など）
- 謎・伏線・予言
- 特定キャラ同士の関係（師弟・対立）

**重要**：
1キャラ＝1ストランドではない。
「物語的に独立して進捗を管理したい単位」がストランド。

### 2. 表の基本構造（ローリング式）

```
行（縦）   ：Chapter（章）
列（横）   ：ストランド（筋）
各マス     ：その章で、その筋をどう動かすか（1〜2行）
```

### 3. YAML / Markdown 分業ルール

**判断基準：「これは機械に渡すか？」**

- YES → YAML（構造・事実・設定）
- NO → Markdown（思考・意図・迷い）

| YAML（機械の真実） | Markdown（人間の余白） |
|---|---|
| 起きた／起こす | なぜそうしたか |
| 進める／止める | 迷い・代替案 |
| 置いた／回収した | 感情・温度・ニュアンス |
| キーが固定できる | 書きながら変わりそうなこと |

**守るべきルール：**
- YAMLは1章あたり30行以内（超えたら設計ミス）
- YAMLは「現在形の事実」だけ書く
- MarkdownはYAMLを参照する（逆はしない）
- YAMLに長文を書かない。Markdownに構造を持たせすぎない

---

## Persistence（永続化）

### ディレクトリ構成

ユーザーの作業ディレクトリ内に以下を生成・管理する。
**複数ストーリーを並行管理できる構造**になっている。

```
stories/
├─ <story-slug>/              # 作品ごとのフォルダ（英小文字・ハイフン）
│  ├─ story.yaml              # 作品メタ情報（タイトル・ジャンル・ステータス）
│  ├─ goal.yaml               # 物語のゴール（終点）
│  ├─ strands.yaml            # 筋の定義（固定）
│  ├─ clues.yaml              # 伏線台帳（置く→回収の対応）
│  ├─ chapters/
│  │  ├─ 01.yaml              # 章の構造データ（主）
│  │  ├─ 01.md                # 章の思考メモ（副・任意）
│  │  ├─ 02.yaml
│  │  └─ ...
│  └─ README.md               # 物語全体のメモ（任意）
├─ <another-slug>/
│  └─ ...
└─ index.yaml                 # 全作品の一覧・現在のアクティブ作品
```

**例：**
```
stories/
├─ phoenix-order/             # ハリポタ5巻風
│  ├─ story.yaml
│  ├─ goal.yaml
│  ├─ strands.yaml
│  ├─ clues.yaml
│  └─ chapters/
├─ detective-noir/            # ミステリー作品
│  └─ ...
└─ index.yaml
```

### 作品管理

#### `stories/index.yaml`（全作品の一覧）

```yaml
active: phoenix-order         # 現在作業中の作品（省略時は明示的に指定を求める）
stories:
  - slug: phoenix-order
    title: "不死鳥の騎士団"
    genre: fantasy
    status: drafting           # planning / drafting / revising / done
  - slug: detective-noir
    title: "夜の探偵"
    genre: mystery
    status: planning
```

#### `stories/<slug>/story.yaml`（作品メタ情報）

```yaml
title: "不死鳥の騎士団"
genre: fantasy
status: drafting
total_chapters: 38             # 予定章数（未定なら ~）
created: 2026-02-10
updated: 2026-02-10
```

### ストーリー選択ルール

1. ユーザーが作品名やslugを指定したら、そのフォルダを対象にする
2. 指定がなければ `index.yaml` の `active` を使う
3. `active` も未設定で複数作品がある場合は、どの作品か質問する
4. 作品が1つだけならそれを使う

### ファイルスキーマ

#### `goal.yaml`

```yaml
ending: "主人公が真実を知り、師を失い、自らの使命を受け入れる"
protagonist_arc: "無知→覚醒→喪失→決意"
```

#### `strands.yaml`

```yaml
strands:
  - id: main
    label: "メインプロット"
    description: "中心となる事件・目的の進行"
  - id: romance
    label: "恋愛／人間関係"
    description: "主要キャラ間の感情の変化"
  - id: org
    label: "組織・対立"
    description: "勢力間の動き"
  - id: mystery
    label: "謎／伏線"
    description: "読者に提示する謎とその解明"
  - id: mentor
    label: "師弟関係"
    description: "師との関係の変化"
```

#### `chapters/13.yaml`（章データ）

```yaml
chapter: 13
time: "10/13"
place: "学校/廊下"
title: "Plots and Resistance"
strands:
  main: "Umbridgeに対する抵抗が表面化"
  mystery: "予言の断片が示唆される"
  romance: ~  # 明示的に「動かさない」
tags:
  - "CLUE:prophecy"
  - "HOLD:romance"
```

#### `chapters/13.md`（思考メモ・任意）

```markdown
## メモ
- この章は重いので恋愛筋はあえて止めた
- 予言は読者に気づかれなくてもOK
- Umbridgeの不快感を最大化したい

## 代替案
- 13章でChoとの接触を入れる案もあったが密度過多になるので見送り
```

#### `clues.yaml`（伏線台帳）

```yaml
clues:
  - id: prophecy
    type: CLUE
    planted: 13
    payoff: 37
    description: "予言の存在が暗示される"
  - id: suspectA
    type: RH  # red herring
    planted: 5
    payoff: 22
    description: "偽犯人Aへの疑惑"
  - id: wand_lore
    type: CLUE
    planted: 8
    payoff: ~  # 未回収
    description: "杖の忠誠に関するヒント"
```

### 空欄の意味（重要）

YAMLでの空欄表現を統一する：

- `~`（null）：**明示的に「この章では動かさない」**
- キーごと省略：**まだ検討していない（未記入）**

---

## Instructions

### Step 0. 作品を選択 or 新規作成する

- 既存作品を操作する場合：ユーザーの指定 or `index.yaml` の `active` を参照
- 新規作品の場合：slug を決めて `stories/<slug>/` を作成し、`story.yaml` と `index.yaml` を更新する

以降のパスはすべて `stories/<slug>/` 配下を指す。

### Step 1. ゴールを固定する

まず `goal.yaml` を作成する。

- 物語（またはシリーズ）の**最終状態**
- 主人公が「何を知り／失い／得て終わるか」

**ここでは詳細な経路は決めない。終点のみ固定する。**

### Step 2. ストランドを定義する

`strands.yaml` を作成する。

以下の基本セットから選び、必要に応じて追加する：
- メイン筋（main）
- サブ筋A：人間関係／恋愛（romance）
- サブ筋B：組織・対立（org）
- サブ筋C：謎／伏線（mystery）
- キャラX：師弟・対立（mentor）

id は英語小文字で短く。作品全体で不変。

### Step 3. 章を作成し、最低限だけ埋める

`chapters/` 配下に章ごとの YAML を作成する。

- 最初は **各章1〜2ストランドだけ**埋めてよい
- 全マスを埋めようとしない（ローリングも空白を多用）
- 思考メモが必要なら同名の .md ファイルを添える

### Step 4. 伏線台帳を管理する

`clues.yaml` に伏線を登録する。

タグ語彙（固定）：
- `CLUE` 伏線・手がかり
- `RH` ミスリード（red herring）
- `PAYOFF` 回収
- `HOLD` あえて進めない判断

planted（置く章）と payoff（効く章）を対応づける。
未回収は `payoff: ~` にする。

### Step 5. 点検する

以下をチェックする：

- 各章で **メイン筋が前進しているか**（chapters/*.yaml を通読）
- 同じストランドが **3〜4章以上 `~` のままでないか**
- 1章で **動かしすぎていないか**（strands が全部埋まっている章は要注意）
- `clues.yaml` で **payoff が `~` のまま残っている伏線**がないか
- 表を Markdown テーブルで一覧出力し、全体の密度バランスを確認

### Step 6. 一覧表を出力する

全章の YAML を読み取り、以下のMarkdownテーブルを生成する：

```markdown
| Ch | Time/Place | Title | main | romance | org | mystery | mentor | Tags |
|----|------------|-------|------|---------|-----|---------|--------|------|
| 1  | ...        | ...   | ...  | ...     | ... | ...     | ...    | ...  |
```

`~` は `—`（emダッシュ）で、省略キーは空欄で表示する。

---

## Examples

### Example 1: ミステリー寄り

strands: 事件(case) / 探索(investigation) / 偽犯人(red_herring) / 真相(truth) / 人間関係(relationship)

### Example 2: 群像劇寄り

strands: 主人公A(protag_a) / 主人公B(protag_b) / 組織(org) / 社会状況(society) / 裏の目的(hidden_agenda)

### Example 3: 恋愛・心理寄り

strands: 外的事件(event) / 内面変化(inner) / 関係進展(progress) / 誤解(misunderstanding) / 決断(decision)

---

## Usage Guidance

* 書き詰まったら「**どのストランドが止まってるか**」→ chapters/*.yaml を grep
* 展開が薄い章は「動かしている筋が少なすぎる」可能性あり
* 逆に重い章は「全部の列が埋まっている」
* `clues.yaml` の未回収（`payoff: ~`）を定期的にチェック
* 思考の経緯を残したいときだけ .md を作る（全章に作る必要はない）

---

## Philosophy (JKR式の思想)

* 終点は固定、経路は可変
* 設計はするが、書く楽しみは殺さない
* 表は **拘束具ではなく、事故防止装置**
* YAMLは機械の真実、Markdownは人間の余白
