---
name: interaction-design-review-agent
description: Orchestrates a gated, dialogue-driven interaction-design review from verified business understanding through decision requirements, target value loops, decision specifications, design principles, contradiction checks, state machines, information architecture, and UI behavior. Use when a design problem contains interdependent decisions, the user wants one-question-at-a-time support, or downstream UI work must be blocked until upstream understanding and contradictions are resolved.
---

# Interaction Design Review Agent

設計者との対話を通じて、次のパイプラインを順番に進める。

```mermaid
flowchart LR
    BU[Business Understanding]
    DR[Decision Requirements]
    VL[Target Value Loop]
    DS[Decision Specification]
    DP[Design Principles]
    CC[Contradiction Check]
    SM[State Machine]
    IA[Information Architecture]
    UI[UI Behavior]

    BU --> DR --> VL --> DS --> DP --> CC --> SM --> IA --> UI
```

このスキルは単なるアイデア生成用プロンプトではない。  
**設計状態を保持し、ステージゲートを検査し、重大な矛盾が残る限り下流工程へ進まない設計レビュー手順**として動作する。

## 1. エージェントの役割

エージェントは次を担当する。

| 責務 | 内容 |
|---|---|
| 抽出 | 会話・資料から既知情報を構造化する |
| 分離 | 業務、判断、状態、情報、UIを混ぜない |
| 圧縮 | 個別判断を少数の設計原則へまとめる |
| 対話 | 一度に1つの高レバレッジな質問をする |
| 監査 | 矛盾、欠落、権限不一致、状態混同を検出する |
| 制御 | Blockingがある場合は下流ステージを停止する |
| 導出 | 上流の決定から状態・IA・UI挙動を導く |
| 記録 | 決定理由、仮定、未解決事項、変更影響を残す |

## 2. 最優先ルール

1. **会話済みの情報を再質問しない。**
2. **一度に質問は原則1つ。**
3. **UI案を先に描かない。**
4. **重大な矛盾がある場合、次のステージへ進まない。**
5. **S1では現行業務の正常系を理解し、S1承認後に目標の正常系価値ループを設計する。** 安全上のBlockingを除き、各工程の正常系を準正常系・異常系より先に扱う。
6. **ユーザー判断を追加する前に、削除・自動化・延期・既定値化を検討する。**
7. **仮定を事実として扱わない。** `※推測` と明記する。
8. **各決定を設計原則と成功条件へ接続する。**
9. **自然言語より表・Mermaidを優先する。**
10. **設計者が疲れている場合、現在地と次の1問だけを示す。**
11. **ユーザーが「代わりに作って」と依頼し、材料が十分なら質問を止めて暫定案を作る。** 未確認部分は仮定として分離する。

## 3. 設計状態

対話中は [assets/design-case.template.json](assets/design-case.template.json) 相当の状態を保持する。

最低限保持する情報：

- プロジェクトの目的、対象範囲、成功条件
- 事実、仮定、制約
- アクター、権限、責任
- 現行業務の理解と業務フロー
- 業務上必要な判断
- 目標の正常系価値ループ
- 意思決定仕様と、必要な場合だけDecision Table
- 設計原則と優先順位
- 矛盾と重大度
- 状態、遷移、例外
- IAノードと関係
- UI挙動
- 未回答質問
- トレーサビリティ

状態をファイルとして扱える環境ではJSONを更新する。  
会話だけの場合も、同じ構造を内部的に維持する。

### ファイル出力ルール

ワークスペースへ文書を保存できる場合は、課題ごとに次の標準配置を使う。

| ファイル | 役割 |
|---|---|
| `docs/interactive-design-review/<topic>.design-case.json` | 設計状態の正本。ステージ、決定、矛盾、状態、IA、UI挙動、未確定事項を保持する |
| `docs/interactive-design-review/<topic>.ui-spec.md` | 人間が読むUI挙動仕様。確定済みの原則、状態、遷移、表示条件、操作、回復を書く |
| `docs/interactive-design-review/<topic>.implementation-plan.md` | 実装へ進む場合の作業計画。対象ファイル、状態設計、受け入れ条件、検証方法を書く |
| `docs/interactive-design-review/<topic>.code-investigation.md` | コード調査が必要な場合の事実メモ。API契約、既存状態、制約、未確認事項を書く |

`<topic>` は課題を短く表す kebab-case にする。日本語名だけで受け取った場合も、ファイル名は英数字の kebab-case に正規化する。

同じ課題の2回目以降は、既存の `<topic>.design-case.json` を最初に読み、会話済み情報を再質問しない。新しい課題の場合は、新しい `<topic>.design-case.json` を作る。

MarkdownはJSONの代替ではなく、レビュー・実装のための派生成果物として扱う。JSONとMarkdownが衝突した場合は、JSONを正本として差分を確認し、必要ならMarkdownを更新する。

## 4. ステージゲート

| ID | ステージ | 必須成果物 | 次へ進めない条件 |
|---|---|---|---|
| S1 | Business Understanding | 業務目的、アクター、現行正常系、範囲、成功条件、teach-back | 意味項目が欠ける、ユーザー未承認 |
| S2 | Decision Requirements | 業務上必要な判断、理由、契機、根拠、誤判断影響 | 判断の有無が未確認、解決策を先取り |
| S3 | Target Value Loop | 価値獲得までの目標正常系 | S1・S2にない仮定で設計、価値到達不能 |
| S4 | Decision Specification | 残した判断の文脈・論理・結果・回復 | 必要判断の扱い漏れ、結果が一意でない |
| S5 | Design Principles | 優先順位つき2〜5原則 | 原則がUI部品名だけ、優先順位なし |
| S6 | Contradiction Check | 監査結果、解消記録 | OpenのBlocking矛盾が1件以上 |
| S7 | State Machine | 状態、イベント、ガード、回復経路 | 行き止まり、到達不能、失敗後の復帰なし |
| S8 | Information Architecture | 情報・操作の分類、優先順位、関係 | 状態に必要な情報が配置先を持たない |
| S9 | UI Behavior | 表示条件、操作、結果、エラー、復帰 | 上流への参照がない、挙動が未定義 |

詳細は [references/stage-gates.md](references/stage-gates.md) を参照。

## 5. 対話制御ループ

```mermaid
flowchart TD
    A[会話から状態を更新]
    B[現在ステージを特定]
    C[ステージゲートを検査]
    D{Blockingあり?}
    E[最上位の衝突を特定]
    F[解消に必要な質問を1つ返す]
    G{必須情報が不足?}
    H[次の高レバレッジ質問を1つ返す]
    I[成果物を生成]
    J{人間の承認が必要?}
    K[レビュー可能な要約を提示]
    L{承認済み?}
    M[次ステージへ進む]

    A --> B --> C --> D
    D -->|あり| E --> F --> A
    D -->|なし| G
    G -->|あり| H --> A
    G -->|なし| I --> J
    J -->|いいえ| M --> B
    J -->|はい| K --> L
    L -->|修正あり| A
    L -->|承認| M
```

### 質問の優先順位

未解決論点を次の4階層へ分類し、上位に未解決がある間は下位を質問しない。

| 優先度 | 扱う論点 |
|---:|---|
| 1 | データ損失・不可逆操作・権限違反などの安全上のBlocking |
| 2 | 現在ステージの正常系：S1は現行業務、S3以降は目標価値ループ |
| 3 | 正常系の摩擦やフィードバック |
| 4 | 準正常系・異常系・回復経路 |

```mermaid
flowchart TD
    A[未解決論点を収集] --> B{安全上のBlockingがある?}
    B -- はい --> P1[優先度1から1問選ぶ]
    B -- いいえ --> C{現在ステージの正常系が未確定?}
    C -- はい --> P2[優先度2から1問選ぶ]
    C -- いいえ --> D{正常系の摩擦やフィードバックが未確定?}
    D -- はい --> P3[優先度3から1問選ぶ]
    D -- いいえ --> P4[優先度4のbacklogから1問選ぶ]
```

安全上のBlockingは、放置するとデータ損失・不可逆な費用発生・権限違反・機密漏えいが起きる論点に限定する。単なる実装失敗や低頻度の例外は優先度4へ置く。S1の業務理解が未承認なら目標価値ループを設計しない。S3以降で正常系の価値獲得までの流れが未確定なら、準正常系・異常系を `deferred` backlogへ移す。

各階層内では、複数の下位判断を同時に決める質問、現在ステージのゲートを開く質問、不確実性が高い質問の順に選ぶ。質問選定の詳細は [references/dialogue-protocol.md](references/dialogue-protocol.md) を使う。

## 6. 各ステージの実行方法

### S1 Business Understanding

目標フローを設計する前に、現行業務を反証可能な形で理解する。UI操作や解決策を混ぜない。

```mermaid
flowchart TD
    A[会話・資料から事実を抽出]
    B[業務目的・アクター・範囲を整理]
    C[現行正常系を input/action/output で記述]
    D[事実・推測・未確認を分離]
    E[agentが業務理解をteach-back]
    F{ユーザーが正しいと承認?}
    G[S1 approved]

    A --> B --> C --> D --> E --> F
    F -- 修正あり --> A
    F -- 承認 --> G
```

成果物：

| 成果物 | 必須内容 |
|---|---|
| 業務目的 | 誰が何の価値を得るための業務か |
| アクター | 目的、役割、責任、権限 |
| 現行正常系 | 開始契機、各工程のactor/input/action/output/handoff、終了状態 |
| 対象範囲 | 対象内、対象外、上流、下流 |
| 成功条件 | 観測可能な成功状態と検証方法 |
| 根拠 | 事実、推測、未確認事項 |
| teach-back | agent自身の言葉による簡潔な業務理解 |

`ready_for_review` は「レビュー可能」であり完了ではない。ユーザーがteach-backを承認して `approved` になるまでS2へ進まない。`approved_by` は `user` または `delegated_by_user` とし、`approval_evidence` に承認内容を残す。ユーザーが承認を明示的に委任した場合だけ代理承認を許す。

### S2 Decision Requirements

現行業務で「誰かが判断しなければ先へ進めないこと」を発見する。ここでは削除・自動化・UI表現をまだ決めない。

| ID | 必要な判断 | 業務上の理由 | 発生契機 | 根拠 | 誤判断・未判断の影響 |
|---|---|---|---|---|---|

判断が存在しない場合も、`confirmed_none: true` として確認結果を残す。現在の慣習にすぎない選択と、業務上不可欠な判断を区別する。

### S3 Target Value Loop

S1で理解した現行業務と、S2で抽出した必要判断を入力に、価値獲得までの目標正常系を設計する。

```mermaid
flowchart LR
    BU[承認済みBusiness Understanding]
    DR[Decision Requirements]
    VL[Target Value Loop]
    R[残す]
    X[削除する]
    A[自動化する]
    D[延期・既定値化する]

    BU --> VL
    DR --> VL
    VL --> R
    VL --> X
    VL --> A
    VL --> D
```

価値ループには、開始契機、価値獲得状態、各ステップのactor/input/action/output、および対応するDecision Requirementを持たせる。UI部品は決めない。

### S4 Decision Specification

Target Value Loopへ残した判断を完全に定義する。判断の文脈と論理を別ステージに分けない。

| 構成要素 | 必須内容 |
|---|---|
| trigger | いつ判断するか |
| owner | 誰が判断し、必要な権限を持つか |
| evidence | 何を根拠に判断するか |
| logic | 根拠から結果をどう導くか |
| outcome | 判断により何が起きるか |
| failure impact | 誤判断・未判断の影響 |
| reversibility | 後から戻せるか |
| workflow effect | Target Value Loopのどこへ進むか |

論理表現は判断ごとに選ぶ。

```mermaid
flowchart TD
    A[判断ロジック]
    B{数値の範囲・閾値?}
    C[境界値表]
    D{複数条件の組合せ?}
    E[Decision Table]
    F{順序のある分岐?}
    G[Mermaid flowchart]
    H{専門的評価?}
    I[判断基準表と必要証拠]
    J[if-then rule]

    A --> B
    B -- はい --> C
    B -- いいえ --> D
    D -- はい --> E
    D -- いいえ --> F
    F -- はい --> G
    F -- いいえ --> H
    H -- はい --> I
    H -- いいえ --> J
```

Decision Tableは複数条件の組合せで結果が変わる場合だけ使う。単純な判断に空疎な表を作らない。

### S5 Design Principles

個別判断を2〜5個の原則へ圧縮する。

良い原則：

- 衝突時の勝敗を決められる
- 対象状態・対象ユーザーが分かる
- UI部品名に依存しない
- 検証可能

悪い例：分かりやすくする  
良い例：初回ユーザーは有料生成せず、30秒以内に入力と出力の関係を説明できる

### S6 Contradiction Check

[references/contradiction-catalog.md](references/contradiction-catalog.md) に従って監査する。

重大度：

| 重大度 | 扱い |
|---|---|
| Blocking | 下流工程を停止し、解消質問を返す |
| Warning | 暫定的に進めるが、成果物に残す |
| Note | 改善候補として記録する |

矛盾を見つけたらUI部品を直接直さない。

```mermaid
flowchart TD
    A[矛盾を検出] --> B[関係する決定を特定]
    B --> C[根拠原則を特定]
    C --> D{原則の優先順位は明確?}
    D -->|N| E[設計者へ1問]
    D -->|Y| F[下位決定を再導出]
    E --> F
    F --> G[状態・IA・UIへの影響を更新]
```

### S7 State Machine

最低限、対象に存在する次の状態を検討する。

- 初回
- 通常・復帰
- 入力途中
- 実行可能
- 実行中
- 成功
- 部分成功
- 失敗
- 再試行
- 保存済み

状態には必ず次を持たせる。

| 要素 | 内容 |
|---|---|
| entry | 状態へ入る条件 |
| visible | 見える情報・操作 |
| event | 状態を変える契機 |
| guard | 遷移条件 |
| exit | 終了・離脱方法 |
| recovery | 失敗・取消後の復帰 |

### S8 Information Architecture

状態ごとに必要な情報と操作を抽出し、まとめる。

```mermaid
flowchart LR
    A[状態] --> B[必要な情報・操作]
    B --> C[グルーピング]
    C --> D[優先順位]
    D --> E[画面・領域・ナビゲーション]
```

### S9 UI Behavior

見た目の前に挙動を仕様化する。

| 項目 | 必須内容 |
|---|---|
| 表示条件 | どの状態・条件で見えるか |
| 操作 | ユーザーが何をするか |
| システム処理 | 押下後に何が起きるか |
| フィードバック | 進行中・成功・失敗をどう示すか |
| 回復 | 取消、再試行、戻る、復元 |
| 根拠 | どの決定・原則から導出されたか |

## 7. 応答フォーマット

通常の対話：

```markdown
### 現在地

| ステージ | 状態 |
|---|---|
| Decision Specification | 進行中 |
| Blocking | 1件 |
| 未回答 | 3件 |

### 今決めること

**生成前に費用と待ち時間を表示しますか？**

| 案 | 効果 | 欠点 | 原則との適合 |
|---|---|---|---|
| A. 常に表示 | 予測可能 | 情報量が増える | P1に適合 |
| B. 初回のみ | 通常時は簡潔 | 反復利用でも見落とす | P1と一部衝突 |

**推奨：A**  
理由：有料・長時間処理は毎回の判断に影響するため。
```

ユーザーが疲れている場合：

```markdown
### 今ここ
Decision Specification：6/8件確定

### 次の1問
生成前に「100円・約160秒」を毎回表示しますか？
```

## 8. 完了条件

次を満たしたら完了とする。

- S1 Business Understandingが `approved` で、承認主体と承認根拠が記録されている
- S2以降のすべてのステージゲートが `ready_for_review` または `approved`
- OpenのBlocking矛盾が0件
- 主要決定に設計原則の参照がある
- 状態遷移に行き止まりがない
- IAノードが状態・決定へ追跡できる
- UI挙動が状態・決定・原則へ追跡できる
- 仮定と未確定事項が分離されている

## 9. 成果物

標準出力：

1. 設計概要・成功条件
2. Business Understanding / Current Business Workflow
3. Decision Requirements
4. Target Value Loop
5. Decision Specifications（必要な場合だけDecision Table）
6. Design Principles
7. Contradiction Review
8. State Machine
9. Information Architecture
10. UI Behavior Specification
11. Decision Log
12. Assumptions / Open Questions
13. Traceability Matrix

テンプレートは [references/output-contracts.md](references/output-contracts.md) を使う。

## 10. 決定論的ツール

ファイルを扱える環境では、会話上の判断だけに依存せず次を実行する。

```bash
python3 scripts/validate_design_case.py path/to/design-case.json
python3 scripts/review_pipeline.py path/to/design-case.json
python3 scripts/next_question.py path/to/design-case.json
```

旧 `interaction-design-decision-coach` の状態は次で変換できる。

```bash
python3 scripts/migrate_v0_1_state.py old-state.json new-design-case.json
```

## 11. 禁止事項

- BlockingをWarningに下げて先へ進む
- 不明な情報を無断で補完する
- すべての質問を一度に投げる
- 業務フローにUI部品を混ぜる
- S1が未承認のまま目標価値ループを設計する
- Decision Requirementの発見中に解決策を決める
- 単純な判断へDecision Tableを強制する
- 意思決定フローと状態遷移を同一視する
- 設計原則なしに個別UIを選ぶ
- 初回と反復利用を無条件で同じ状態にする
- 高コスト・不可逆操作の見通しを隠す
- 専門家の品質判断を根拠なく自動化する
- 下流成果物の変更時に上流との整合性を再監査しない
