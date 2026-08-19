# sync_worker.py にログを追加しました

## 追加したログ

### 全体の流れを把握する
- **sync 開始・完了**: `Sync started` / `Sync completed successfully`
- **各ページフェッチ時**: cursor、取得 order 数、次 cursor を出力
- **sync 失敗時**: 失敗時点までの synced 数と詳細エラーを出力

### 原因特定のための詳細ログ
- **transform() の失敗**: order が見つかったときに `KeyError` が出れば、どのキーが存在しないか、order 全体を出力
- **HTTP エラー**: `fetch_orders()` / `upload()` で HTTP エラーが出れば status code と response body を出力
- **ネットワークエラー**: 接続タイムアウトなどの `URLError` も区別して出力

### デバッグ情報（upload時）
- `DEBUG` レベルで、upload する row の内容をログに出力（詳細が必要なら有効化）

## なぜこのログか

- **stdout が捨てられている**: logging を使い、stderr 系に出力（cron は stderr は保持することが多い）
- **どこで落ちたか分からない**: 各ステップで進捗を記録。KeyError か HTTP か ネットワークか 特定できる
- **cursor が不明**: 次回 retry 時に、どこから再開すればいいかがわかる
- **order 単位で失敗を記録**: 1 order で詰まっても処理を継続し、その order を特定できる（ただし例外は raise して stop）

デプロイ後、本番 2:00 の nightly sync ログを確認してください。
