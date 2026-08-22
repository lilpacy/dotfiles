# invoice-receive: ai_unavailable diagnostics — 経緯

これまでの経緯（このスレッドの前段）:

- 2日前: invoice OCR job `253175` が `ai_unavailable` で失敗しているのを検知。診断のため、Gemini呼び出し失敗時のエラーコードを `ocr_jobs.last_error` に出すログを追加した（PR #952、staging限定）。
- 1日前: エラーコードだけでは原因が分からなかったため、レビューで「message も出すべき」と指摘があり対応した（PR #957）。
- 今日: message でもまだ切り分けに足りないとレビューで指摘があった。「Gemini呼び出しの request 内容（model, schema, config）と、失敗直前の状態」も合わせてログに残すよう追加対応してほしい。

対象は `invoice-receive` サービスの OCR パイプライン。前回・前々回の diff は `logging/` 配下に既にある想定（このワークスペースにはダミーとして置いていないが、方針は上記の通り）。

## 今のDBの状態

`schema.sql` / `seed_and_query.py` で staging DB を再現できる（`python3 seed_and_query.py`）。`ocr_jobs` と `attachments` を読める。
