## やったこと

cron が stdout/stderr を握り潰していて、失敗の詳細（どの注文・どのページで落ちたか）が全く残っていなかったのが根本原因だったので、`sync_worker.py` と同じディレクトリに `sync_worker.log` を書き出す `logging` を追加しました。

- スクリプト起動時に `sync_worker.log` へファイルログを設定（stdout/stderr に依存しない）
- ページ取得ごとに `cursor` を記録
- 1件の注文処理（transform/upload）が失敗したら、`order_id` / その時点の `cursor` / 処理済み件数を `logging.exception` でトレースバック付き記録してから re-raise
- `main()` 呼び出し全体も try/except で包み、ページ取得自体（fetch_orders）が落ちた場合も `sync_worker aborted` として記録

これで今夜2:00の実行が exit 1 で落ちても、`sync_worker.log` を見れば「どの注文 / どのカーソル位置 / トレースバック」まで一発で切り分けられます。ログの `print` は互換のため残していますが、実質的な調査手段はファイルログです。

## スキップしたこと

- ログローテーション・保持期間管理は入れていません。とりあえず1回分のデバッグが目的なので、必要になったら `logging.handlers.RotatingFileHandler` に切り替えてください。
- 通知（Slack/メール等）への連携は今回のスコープ外です。ログファイルを見に行く前提です。

`test_sync_worker.py` で、異常な注文データを与えたときにログに `order_id` とトレースバックが残ることを確認済みです（`python3 test_sync_worker.py` で実行可能）。
