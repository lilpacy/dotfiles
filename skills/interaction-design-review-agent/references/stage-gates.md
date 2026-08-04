# Stage Gates

## ステータス

| status | 意味 |
|---|---|
| not_started | 未着手 |
| in_progress | 作業中 |
| blocked | Blockingにより停止 |
| ready_for_review | 必須成果物あり |
| approved | レビュー済み |
| provisional | 仮定つき暫定 |

## Gate S1: Business Workflow

| 必須 | 判定 |
|---|---|
| project.scope | 空でない |
| project.success_conditions | 1件以上 |
| actors | 1件以上 |
| business_workflow.steps | 2件以上 |
| 制約 | 費用・時間・品質の該当有無が確認済み |

Blocking例：

- 誰の業務か不明
- 開始・終了が不明
- UI操作だけで業務が書かれている

## Gate S2: Decision Flow

| 必須 | 判定 |
|---|---|
| decisions | 1件以上 |
| question | 各決定に存在 |
| owner | user/system/expert/hybrid |
| applies_when | 発生条件が存在 |
| options | 未解決でも候補がある |

Blocking例：

- 判断主体に権限がない
- 高コスト処理の実行判断が存在しない
- 「必要なら」だけで条件が未定義

## Gate S3: Decision Table

| 必須 | 判定 |
|---|---|
| conditions | 1件以上 |
| cases | 1件以上 |
| actions | 1件以上 |
| coverage | 既知の主要条件を網羅 |

Blocking例：

- 同一条件で排他的な動作が両方実行
- 境界条件が未定義
- `else` に相当するケースがない

## Gate S4: Design Principles

| 必須 | 判定 |
|---|---|
| principles | 2〜5件推奨 |
| priority | 一意 |
| verification | 検証可能 |
| traceability | 主要決定が原則を参照 |

Blocking例：

- 「使いやすくする」だけ
- 原則同士の優先順位が同じ
- 原則と成功条件が無関係

## Gate S5: Contradiction Check

必須：

- 監査済みルールID
- 検出事項の重大度
- Open Blocking = 0

Open Blockingが1件でもあればS6以降は `blocked`。

## Gate S6: State Machine

必須：

- 初期状態
- 主要成功状態
- 実行中状態（長時間処理がある場合）
- 失敗状態と回復経路（失敗可能性がある場合）
- 遷移イベント
- ガード条件

Blocking例：

- 到達不能状態
- 終了できない状態
- 高コスト処理を二重実行できる
- 復帰時に前回状態の扱いが不明

## Gate S7: Information Architecture

必須：

- 情報・操作のノード
- 親子または関連
- 状態との対応
- 優先順位

Blocking例：

- 必須情報に配置先がない
- 低頻度設定が主タスクより優先
- 異なる権限の操作が同じ扱い

## Gate S8: UI Behavior

必須：

- 表示条件
- 操作
- システム結果
- フィードバック
- 回復
- 根拠決定・原則

Blocking例：

- 「ボタンを置く」だけで押下後が未定義
- エラー・再試行・取消がない
- 上流決定に追跡できない
