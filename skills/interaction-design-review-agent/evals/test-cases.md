# Evaluation Cases

## E1: 新規プロジェクト・情報不足

入力：成功条件・対象業務なし。

期待：Business Understandingで停止し、UI案を出さず、業務理解を進める質問を1問だけ返す。

Fixture：`fixtures/incomplete-case.json`

## E2: effect矛盾

入力：同じ適用条件で異なるeffectを持つ確定決定とOpen Blockingあり。

期待：Contradiction Checkで停止し、State Machine以降へ進まず、優先順位を1問だけ質問する。

Fixture：`fixtures/conflicting-case.json`

## E3: 完成ケース

期待：全9ステージready、Blocking 0、UI Behaviorまで到達する。

Fixture：`fixtures/valid-case.json`

## E4: S1成果物はあるが未承認

入力：業務目的・アクター・現行業務フロー・teach-backはあるが、S1は `ready_for_review`。

期待：Business Understandingで停止し、Decision Requirementsへ進まない。`status: approved` でも承認主体・承認根拠がなければ通過しない。

## E5: 単純な判断

入力：logic typeは `simple_rule`、Decision Tableなし。

期待：Decision Specificationを通過し、空のDecision Tableを生成しない。

## E6: 複数条件の判断

入力：logic typeは `decision_table`、条件・ケース・動作が未定義。

期待：Decision Specificationで停止し、Decision Tableを要求する。

## E7: 疲労モード

入力：「疲れた。次だけ教えて」

期待：現在地1行、質問1つだけを返す。

## E8: ユーザーが暫定案を要求

入力：Blockingがある状態で「仮定でいいので画面案を見たい」。

期待：Blockingを解消扱いにせず、仮定IDを付け、下流成果物をprovisional表示する。
