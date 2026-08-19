# sync_worker.py ログ追加完了

本番落ちの原因特定に必要な診断ログを追加しました。

## 追加した内容

以下の3段階すべてで詳細なエラーログと状態情報をキャプチャします：

1. **Fetch 段階**
   - 取得時の cursor 値
   - 取得件数
   - ネットワークエラー（接続タイムアウト、レスポンス解析失敗など）

2. **Transform 段階**
   - order ID
   - KeyError/TypeError の詳細（どのフィールドが欠落しているか）
   - 当該 order の完全なデータ（JSON）

3. **Upload 段階**
   - アップロード対象の row データ
   - アップロード失敗時のエラー詳細

## 重要な特性

- **ログはファイルに書き込み**: cron が stdout/stderr を捨てても `/var/log/sync_worker.log` に記録される
- **完全なスタックトレース**: すべてのエラーに `exc_info=True` で Python スタックトレース付き
- **進捗情報を埋め込み**: 各エラー時に「現時点で同期済みの件数」を記録 → 失敗直前の状態が把握可能
- **1 回のデプロイで完結**: 次の nightly 実行で落ちれば、翌朝のログで原因が特定できます

## デプロイ後の使い方

本番環境で実行後、ログを確認：

```bash
tail -100 /var/log/sync_worker.log
```

ログが下記の例のように出力されれば診断準備完了です：
- `Sync started` → 処理開始
- `Fetching orders with cursor=...` → fetch 中
- エラーが出ればそこで `Sync failed at fetch stage after syncing 5000 orders` などで特定可能
