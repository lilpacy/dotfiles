# Contradiction Catalog

## 重大度

| severity | 基準 |
|---|---|
| blocking | 目的達成不能、課金・不可逆、権限逸脱、行き止まり |
| warning | 認知負荷、一貫性低下、説明不足、例外漏れ |
| note | 改善候補 |

## 監査ルール

| ID | 規則 | 典型例 | 既定重大度 |
|---|---|---|---|
| C01 | 原則矛盾 | 「初回は無料理解優先」なのに学習用有料生成 | blocking |
| C02 | effect衝突 | 同じ状態でサンプルを常時表示／初回のみ表示 | blocking |
| C03 | 判断主体の権限不足 | アシスタントが作画品質の最終採否を決める | blocking |
| C04 | コスト非表示 | 100円・160秒を実行前に示さない | blocking |
| C05 | 状態混同 | 初回と反復利用で同じオンボーディング | warning |
| C06 | 必須／任意不一致 | 必須設定が詳細設定内に隠れる | blocking |
| C07 | 因果不透明 | 入力が出力の何に効くか分からない | warning |
| C08 | 回復欠落 | 生成失敗後に再試行・戻るがない | blocking |
| C09 | 前回状態の危険な復元 | 別カットの設定を誤用しやすい | warning |
| C10 | 時系列矛盾 | 結果確認後にしか分からない情報を生成前に必須化 | blocking |
| C11 | 局所最適 | 個別補助を足し続け主タスクが埋もれる | warning |
| C12 | 例外漏れ | 「通常はキャラ設定あり」以外の処理なし | warning |
| C13 | 重複実行 | 長時間・有料処理を連打可能 | blocking |
| C14 | トレーサビリティ欠落 | UI要素に根拠となる決定がない | warning |
| C15 | 終了条件欠落 | 保存後に次工程へ渡す方法がない | blocking |
| C16 | 原則の同順位 | 衝突時に解けない | warning |
| C17 | サンプルと実データの混同 | 見本を実案件として誤保存 | blocking |
| C18 | 専門評価の支援不足 | 作監が比較に必要な元画像を見られない | warning |

## 解消レコード

| 項目 | 内容 |
|---|---|
| contradiction_id | Cxx |
| status | open / resolved / accepted_risk |
| resolution | 何を変更したか |
| changed_decisions | 更新した決定 |
| invalidated_outputs | staleにした下流成果物 |
| approved_by | リスクを受け入れた主体 |
