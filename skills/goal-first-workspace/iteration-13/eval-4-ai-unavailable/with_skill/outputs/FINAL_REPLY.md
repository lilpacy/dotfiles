`ai_unavailable` は `errors.js` で `AIProviderError` を丸めて返しているだけの表示用コードなので、staging のログを見てもそれ以上の情報が出ないのは想定通りでした。原因の切り分けに必要な情報は `generateHandler.js` や `errors.js` ではなく、実際に provider へリクエストしている `aiClient.js` の catch 部分が握って捨てていたので、そこにログを追加しました。

追加したログ（`aiClient.js`）:
- fetch 自体が例外を投げたケース（プロキシ疎通不可・タイムアウトなど）: `vendorId`, `elapsedMs`, `errName`（`TimeoutError` か `ECONNREFUSED` かなどを区別できます）, `errCode`, `errMessage`
- provider が non-2xx を返したケース: `vendorId`, `elapsedMs`, `status`, `x-error-code` ヘッダ, レスポンスボディの先頭500文字

これで次に `ai_unavailable` が出たときのログだけで「タイムアウトか / 社内 proxy への疎通失敗か / provider 自体が 4xx・5xx を返しているか」を区別できます。ローカルでは再現せず、staging への反映が1往復1〜2時間かかる制約があるので、1回のデプロイで全パターンを判別できるだけの情報を最初から仕込んでいます（後から1項目ずつ足すと往復コストがかさむため）。

動作確認: fetch がネットワーク例外を投げるケースと、fetch が 502 を返すケースをそれぞれモックして実行し、想定した構造化ログが出ることを確認済みです。

```
[aiClient] provider request failed {"vendorId":"v1","elapsedMs":0,"errName":"FetchError","errCode":"ECONNREFUSED","errMessage":"connect ECONNREFUSED"}
[aiClient] provider returned non-2xx {"vendorId":"v2","elapsedMs":0,"status":502,"code":"UPSTREAM_502","bodySnippet":"<html>Bad Gateway from proxy</html>"}
```

次にやること: このログを staging にデプロイして実際の `ai_unavailable` 発生時のログを見てください。`errName`/`status` が出れば、社内 proxy 側の問題か provider 側の問題かがそこで判断できます。
