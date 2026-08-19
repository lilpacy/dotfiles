# 対応完了

staging の `ai_unavailable` エラーの原因特定に必要なログを追加しました。

## 追加した情報

ログには以下の情報が JSON 形式で出力されるようになります：

1. **リクエスト情報**
   - `prompt` の長さ（パターン検出用）
   - `vendorId`

2. **エラーの発生段階**
   - fetch 失敗（timeout 含む）vs HTTP エラー応答
   - `details.step` で判定可能

3. **Provider からの詳細レスポンス**
   - HTTP ステータスコード（502、503 など）
   - `x-error-code` ヘッダ値
   - レスポンス本体（先頭 2000 文字）
   - Content-Type ヘッダ

4. **タイムアウト検出**
   - AbortError の有無を `details.isTimeout` で区別

これらにより、社内 proxy での問題、provider の過負荷、network の問題などを切り分けられます。

## 例：出力ログ

```json
{
  "error": "ai_unavailable",
  "httpStatus": 503,
  "request": {
    "promptLength": 245,
    "vendorId": "acme-corp"
  },
  "provider": {
    "status": 502,
    "errorCode": "SERVICE_UNAVAILABLE",
    "details": {
      "step": "response",
      "responseStatus": 502,
      "responseHeaders": {
        "errorCode": "SERVICE_UNAVAILABLE",
        "contentType": "application/json"
      },
      "responseBody": "{\"error\": \"backend timeout\"}"
    },
    "message": "provider returned non-2xx"
  }
}
```
