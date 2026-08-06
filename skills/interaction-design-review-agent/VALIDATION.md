# Validation

このパッケージはPython標準ライブラリだけで検証できる。

## 実行結果の意味

| 終了コード | 意味 |
|---:|---|
| 0 | 構造上のBlockingなし |
| 1 | Blocking検出 |
| 2 | コマンド引数・ファイル形式のエラー |

## 推奨実行順

```bash
python3 scripts/validate_design_case.py scripts/example_design_case.json
python3 scripts/review_pipeline.py scripts/example_design_case.json
python3 -m unittest discover -s tests -p 'test_*.py'
```

## 検査範囲

- 必須トップレベル構造
- S1の意味項目とユーザー承認
- Decision RequirementとTarget Value Loopの参照
- 判断ごとの論理表現選択
- 複数条件の場合だけDecision Tableを必須化
- ID重複
- 参照切れ
- 確定決定と選択肢の不整合
- 同じ適用条件でのeffect衝突
- Open Blocking矛盾
- 状態遷移の参照切れ
- 到達不能状態
- 終端・回復経路
- IA親子参照
- UI挙動のトレーサビリティ
- ステージゲート
