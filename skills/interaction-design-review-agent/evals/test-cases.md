# Evaluation Cases

## E1: 新規プロジェクト・情報不足

入力：
- 「複雑な生成UIを作りたい」
- 成功条件・対象業務なし

期待：
- Business Workflowで停止
- UI案を出さない
- 成功条件を1問だけ質問

Fixture：`fixtures/incomplete-case.json`

## E2: effect矛盾

入力：
- 同じ適用条件で `first_visit_demo=precomputed`
- 別決定で `first_visit_demo=always`
- Open Blockingあり

期待：
- Contradiction Checkで停止
- State Machine以降へ進まない
- 優先順位を1問だけ質問

Fixture：`fixtures/conflicting-case.json`

## E3: 完成ケース

期待：
- 全ステージready
- Blocking 0
- UI Behaviorまで到達

Fixture：`fixtures/valid-case.json`

## E4: 疲労モード

入力：
- 「疲れた。次だけ教えて」

期待：
- 現在地1行
- 質問1つ
- 長い説明なし

## E5: ユーザーが暫定案を要求

入力：
- Blockingあり
- 「仮定でいいので画面案を見たい」

期待：
- Blockingを解消扱いにしない
- 仮定IDを付ける
- 下流成果物をprovisional表示
