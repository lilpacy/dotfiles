# Stage Gates

## ステータス

| status | 意味 |
|---|---|
| not_started | 未着手 |
| in_progress | 作業中 |
| blocked | Blockingにより停止 |
| ready_for_review | 必須成果物があり、人間がレビュー可能 |
| approved | レビュー済み |
| provisional | 仮定つき暫定 |

## Gate S1: Business Understanding

| 必須 | 判定 |
|---|---|
| 業務目的 | 誰が何の価値を得る業務か説明できる |
| project.scope | 対象内・対象外が明示される |
| project.success_conditions | 成功状態と検証方法が1件以上ある |
| actors | 各アクターに目的・役割・責任・権限がある |
| business_workflow | 開始・終了と2件以上の現行正常系ステップがある |
| workflow step | actor・input・action・output・handoffがある |
| grounding | 事実・推測・未確認事項が分離される |
| teach_back | agentが業務理解を簡潔に再説明する |
| approval | `approved_by` が `user` または `delegated_by_user` で、`approval_evidence` がある |

`ready_for_review` のままS2へ進まない。S1だけは `approved` を必須とする。

Blocking例：

- 誰の何のための業務か説明できない
- 開始契機または終了状態が不明
- ステップ名だけで入出力や引き渡しがない
- UI操作を現行業務として記述している
- 重要な推測を事実として扱っている
- ユーザーが理解内容を未確認

## Gate S2: Decision Requirements

| 必須 | 判定 |
|---|---|
| presence | 必要判断が1件以上、または `confirmed_none: true` |
| question | 何を判断する必要があるか |
| business_reason | なぜ業務上必要か |
| trigger | いつ判断が発生するか |
| evidence | 判断に必要な根拠 |
| failure_impact | 誤判断・未判断の影響 |
| traceability | 現行業務ステップを参照する |

Blocking例：

- 判断の有無を確認していない
- 現在の慣習と業務上不可欠な判断を区別していない
- この段階で自動化方法やUIを決めている

## Gate S3: Target Value Loop

必須：

- 開始契機
- 観測可能な価値獲得状態
- 2件以上の正常系ステップ
- 各ステップのactor・input・action・output・handoff
- 対応するDecision Requirement
- 削除・自動化・延期・既定値化・人間へ残す判断の記録

Blocking例：

- S1が未承認
- 業務価値へ到達しない
- 必要判断を根拠なく消している
- UI部品を使ってしか流れを説明できない

## Gate S4: Decision Specification

各Decision Requirementの扱いを漏れなく記録する。残す判断には次を必須とする。

- trigger
- ownerとauthority
- evidence
- logic type
- options / outcomes
- failure impact
- reversibility
- Target Value Loopへの接続

論理表現の選択：

| 条件 | 必須表現 |
|---|---|
| 単純な一条件 | if-then rule |
| 順序のある分岐 | flowchart |
| 複数条件の組合せ | Decision Table |
| 数値の範囲・閾値 | 境界値表 |
| 専門的評価 | 判断基準表＋必要証拠 |

Decision Tableは条件に該当する場合だけ必須。全ケースが一意の結果を持ち、未該当・不明条件の扱いが必要である。

## Gate S5: Design Principles

- 原則は2〜5件を推奨
- 優先順位が一意
- 検証可能
- 主要決定が原則を参照
- 原則が成功条件へ接続

## Gate S6: Contradiction Check

監査済みルールID、重大度、解消状態を持つ。Open Blockingが1件でもあればS7以降は `blocked`。

## Gate S7: State Machine

初期状態、主要成功状態、必要な処理中・失敗状態、遷移イベント、ガード、回復経路を持つ。到達不能、終了不能、二重実行、復帰先不明をBlockingとする。

## Gate S8: Information Architecture

情報・操作のノード、親子または関連、状態との対応、優先順位を持つ。必須情報の配置先欠落、権限の異なる操作の混同をBlockingとする。

## Gate S9: UI Behavior

表示条件、操作、システム結果、フィードバック、回復、根拠決定・原則を持つ。「ボタンを置く」だけ、エラー後の復帰なし、上流への参照なしをBlockingとする。
