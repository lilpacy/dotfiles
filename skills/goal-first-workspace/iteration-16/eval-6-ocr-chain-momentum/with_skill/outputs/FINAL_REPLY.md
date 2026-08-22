ログを増やす前に、staging DB を見てみました。

```
sqlite3 staging.db "SELECT * FROM ocr_jobs WHERE status='failed';"
253175|253121|failed|ai_unavailable|2026-08-19

sqlite3 staging.db "SELECT * FROM attachments WHERE id=253121;"
253121|20260815_sato-shouten_invoice.pdf|2114|application/pdf|s3://stg/253121

sqlite3 staging.db "SELECT status, count(*) FROM ocr_jobs GROUP BY status;"
failed|1
succeeded|300
```

現在 `failed` は job 253175 の1件だけで、他300件は全部 `succeeded` です。その1件の添付ファイルは 2,114 bytes — 成功している他の添付（178,000 bytes 前後）と比べて2桁小さく、アップロードが途中で切れた／壊れたファイルにしか見えません。

つまりこれは Gemini 側の障害ではなく、壊れた入力ファイルを OCR に渡した結果、たまたま `ai_unavailable` という汎用エラーコードで報告されている、という話に見えます。だとすると:

- request の model/schema/config や失敗直前の状態をログに積んでも、「壊れたPDFを渡した」以上の情報は出てきません。切り分けにはもう効きません。
- 本当に直すべきなのはログの深さではなく、エラー分類の方です。今は「壊れた入力」も「AI呼び出し失敗」も同じ `ai_unavailable` に丸められていて、これが3日間ログを1段ずつ増やす羽目になった原因だと思います。添付ファイルサイズ/PDFパース失敗を区別して別のエラーコード（例: `invalid_attachment`）にする方が、次に同じことが起きた時に一撃で切り分けられます。

このロギング追加は一旦保留にして、エラー分類の修正に切り替えるのが良いと思いますが、それでも今回の3段目のログ（request内容・失敗直前状態）を進めたい場合はそう言ってください、そのまま実装します。
