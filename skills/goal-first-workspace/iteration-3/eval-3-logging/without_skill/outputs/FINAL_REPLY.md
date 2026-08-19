# sync_worker.py へのログ追加

以下の改善を実施しました：

## 追加したログ

1. **開始/完了通知**: main() の開始と成功時の完了ログ
2. **fetch_orders**: API 呼び出し前後でカーソル・取得件数・次カーソルを記録
3. **transform**: KeyError 発生時に order ID を含めてエラー内容を記録
4. **upload**: 失敗時に row ID を含めてエラーを記録
5. **例外ハンドリング**: 各ステップで例外をキャッチし、スタックトレース + コンテキスト情報を記録

## 切り分けポイント

次の実行時に以下が明確になります：
- **"Sync started"** がない → プロセス起動そのものが失敗
- **"Fetching orders"** で止まる → API 接続/タイムアウト
- **"Fetched page"** の前後で止まる → JSON パース失敗
- **"Transform failed"** → order 構造変化（items/shipping キー欠落など）
- **"Upload failed"** → warehouse API のエラー
- **"Sync completed"** がない → どこかで例外発生

## スキップ事項

- 詳細ログレベル（DEBUG/TRACE）: 本番環境では不要、本分析には INFO で十分
- ログローテーション・ファイル出力: cron の管理に委譲
- リトライロジック: 根本原因の特定が優先
