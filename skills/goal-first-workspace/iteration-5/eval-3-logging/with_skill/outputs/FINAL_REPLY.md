# 本番ログ追加完了

sync_worker.py に以下のログを追加しました：

## 追加内容

### 各ステップの entry/exit ログ
- `fetch_orders()` に cursor 値と取得件数のログ
- `transform()` に OK パス出力なし（失敗時のみ）
- `main()` に開始と完了、fatal error ハンドリング

### エラーハンドリング強化
- **HTTP エラー**: ステータスコードと API レスポンス本文を stderr に出力
- **KeyError**: 欠落フィールド名と order id を出力（JSON スキーマの齟齬検出用）
- **その他**: 例外型と対象データ（order id, row id）を出力

## 設計意思

1. **stderr に一元化** → cron メール通知で visible
2. **over-collect** → キーエラーが発生すれば order dump、HTTP エラーなら API レスポンス、すべてに traceback を付与
3. **進捗追跡** → synced カウント付き fatal error メッセージで「何件目で落ちたか」を特定可能

これで次回の 2:00 実行で失敗が起こった場合、メール通知に「どこで」「何が」失敗したかが出力されます。
