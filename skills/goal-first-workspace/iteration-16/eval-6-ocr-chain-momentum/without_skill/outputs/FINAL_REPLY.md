ログを追加する前に、staging DB を見てみました。今この場で無料で分かることがあったので、先に共有します。

```sql
SELECT j.id, j.status, j.last_error, a.filename, a.size_bytes, a.content_type
FROM ocr_jobs j JOIN attachments a ON j.attachment_id = a.id
WHERE j.id = 253175;
```

```
253175|failed|ai_unavailable|20260815_sato-shouten_invoice.pdf|2114|application/pdf
```

同じ日に処理された他の請求書PDFのサイズ帯（正常終了分）:

```
min=178000  avg=206250  max=236500
```

対象ファイル `20260815_sato-shouten_invoice.pdf` は **2,114 バイト** しかありません。正常な請求書PDFが178KB〜236KBなのに対して約1/100で、典型的な「アップロード途中でクライアントが切断した / 空PDFに近い」サイズです。

これが正しければ、`ai_unavailable` は Gemini 側の設定・リクエスト内容の問題ではなく、**中身がほぼ空の壊れたPDFを渡していて、Gemini が処理不能として弾いている**だけの可能性が高いです。この場合、model/schema/config をログに出しても新しい情報は増えません（毎回同じ設定値が出るだけ）。

なので、追加ログを実装する前に、まずこの仮説を安く検証したいです。

- S3 (`s3://stg/253121`) の実ファイルを開いてPDFとして壊れていないか確認する
- 同じ症状（`ai_unavailable`）の失敗job全件で、attachment サイズが同様に異常値かどうか集計する（1件で終わらせない）

この2つは今日のログ追加より手間が小さく、当たっていれば「Gemini呼び出しログを積む」方向自体が的外れだったと分かります。もし外れていたら（=ファイルは正常なのに失敗している）、その時点で request 内容と失敗直前状態のログを追加する対応に進みます。

先にこちらを確認してよいですか、それとも予定通りログ追加を優先しますか？
