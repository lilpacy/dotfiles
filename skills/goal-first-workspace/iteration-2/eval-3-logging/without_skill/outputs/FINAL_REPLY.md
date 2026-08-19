`sync_worker.py` にログを追加しました。ポイントは **cron が stdout/stderr を捨てている** ことなので、`print` を足しても今夜も同じ「exit 1 しか分からない」状態になります。そこで出力先をファイルに変えてあります。

## 出力先

環境変数 `SYNC_WORKER_LOG`、既定は `/tmp/sync_worker.log`。cron 側の設定変更は不要です（変更が必要なら CI 40 分がもう一往復するため、あえてコード内で完結させました）。永続パスに置きたい場合は cron の行に `SYNC_WORKER_LOG=/var/log/sync_worker.log` を足すだけで切り替わります。

## 今夜落ちたときに分かること

今回の障害で欲しかったのは「どこまで進んで、どのデータで死んだか」の一点なので、そこに絞って入れました。

- 各ページ取得時の `cursor`、件数、累積 synced 件数 — どこまで進んだか
- 失敗したレコードの `id` と生の JSON（2000 文字で切っています） — ローカル再現できない原因そのもの
- 例外のスタックトレース — `transform` のどのキーが無いのか等が特定できる
- HTTP 失敗時はステータス、reason、**レスポンスボディ** — API 側の言い分はここにしか出ません
- 終了時に「何件目・どの cursor で中断したか」のサマリ1行

## 動作確認

`shipping.address` が欠けた壊れたレコードを流す自己チェックを `test_sync_worker.py` に置いて、実際に走らせて確認済みです。実ログ出力:

```
INFO  page 2 cursor='c2' orders=1 synced_so_far=1
ERROR order failed page=2 cursor='c2' id='bad-9' synced_so_far=1 raw={"id": "bad-9", ..., "shipping": {}}
      Traceback ... KeyError: 'address'
ERROR aborted after 1 orders, page=2 cursor='c2': KeyError: 'address'
```

`python3 test_sync_worker.py` で再実行できます。

## 意図的にやっていないこと

- **リトライやエラースキップは入れていません。** 今回の依頼は切り分けなので、挙動を変えると「今夜も落ちる」という再現条件が消えます。原因が分かってから直す方が安全です。
- **成功レコードの生データはログに出していません。** 失敗分のみ。全件出すと夜間バッチでログが膨れます。
- ログ集約基盤への送信やローテーションは入れていません。1晩の切り分けには過剰なので、常設運用に移す段階で。

なお `raw=` には注文データがそのまま入るため、個人情報を含む環境なら出力先のパーミッションにご注意ください。マスキングが必要なら対応します。
