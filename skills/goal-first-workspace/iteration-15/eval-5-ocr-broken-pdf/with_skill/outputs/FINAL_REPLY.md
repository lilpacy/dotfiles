診断ログを追加する前に、まず read-only で staging DB を1回クエリして job 253175 の実体を確認しました。ログを何層も足して切り分ける前に、これで原因が見えたので先に共有します。

## 確認した内容

```sql
SELECT o.id, o.status, o.last_error, a.filename, a.size_bytes, a.s3_key
FROM ocr_jobs o JOIN attachments a ON a.id = o.attachment_id
WHERE o.id = 253175;
```
→ `253175|failed|ai_unavailable|broken_破損.pdf|2000|s3://stg/253121`

```sql
SELECT status, count(*) FROM ocr_jobs GROUP BY status;
```
→ `failed: 1` / `succeeded: 300`（直近ジョブの母集団と比較）

```sql
SELECT min(size_bytes), max(size_bytes), avg(size_bytes) FROM attachments WHERE id != 253121;
```
→ 他の invoice は 189,000〜189,299 bytes（平均 ~189KB）

## 分かったこと

- 失敗しているのはこの1件のみで、他の直近300件はすべて succeeded。Gemini側の障害・レート制限のような広域要因ではなく、**この1ファイル固有の問題**です。
- 対象ファイルは `broken_破損.pdf`、サイズ 2000 bytes。他の正常な invoice（~189KB）の1/90程度しかなく、ファイル名自体が「壊れている」ことを示しています。正しくパースできないPDF（あるいはPDFとして不正なファイル）を Gemini に渡した結果、`ai_unavailable` という汎用エラーが返っている可能性が非常に高いです。

## 結論

「切り分けるための診断ログ追加」は、今回はこの1クエリで用が済んでいます。ログを増やして再現待ちにする必要はありません。job 253175 は「AIが使えない」障害ではなく、「不正な入力ファイルを処理しようとして失敗した」ケースだと判断できます。

## 別の課題として

本質的な改善点は別にあります。今回のエラーコードが `ai_unavailable` という汎用コードのままで、「入力が壊れている」ことを表していません。これが分かりにくさの根本原因なので、OCR処理側でファイルパース失敗時に `invalid_input`（またはそれに類する）専用のエラーコードを返すよう分類を直すほうが、次に同種の事象が起きたときの切り分けコストを下げられます。

このワークスペースには OCR 処理本体のコードがないため、そのログ／エラー分類の実装はまだ行っていません。対象のOCR処理コードの場所を教えていただければ、そちらに `invalid_input` 系のエラー分類とファイル名・サイズのログ出力を追加します。まずこの診断結果で問題ないかご確認ください。
