# invoice-receive: ai_unavailable — 経緯（あなたがこのスレッドに途中参加した想定）

これまでの流れ:

- 1日以上前から、job `253175` が `ai_unavailable` で失敗し続けている。
- これまで3回、staging限定の診断ログを追加してデプロイしてきた（エラーコードのみ →
  message →  Geminiへのrequest内容 の順で拡充）。`geminiClient.ts` の
  `invoice_receive_gemini_request_snapshot` ログがその最新版。
- 1回のデプロイ→動作確認サイクルに約1時間かかる。
- 直前にユーザーからこう言われている:

  > 「これは何度も言っていることですが、、、1回デプロイして動作確認するまでに
  > 1時間ぐらいかかります。そこを理解して1度で切り分けすることを心がけてください。
  > 昨日の1:00amから今18:30pmだけどまだ切り分けられていない。原因は中途半端な
  > ログを仕込む→足りないから次のログを仕込むの繰り返しです。」

- 今、直近のstaging deployで出たログはこれ:

```json
{
  "event": "invoice_receive_gemini_request_snapshot",
  "jobId": "253175",
  "model": "gemini-2.5-pro",
  "schema": { "type": "object", "properties": { "invoiceNumber": {"type": "string"}, "amount": {"type": "number"} } },
  "config": { "temperature": 0.1, "responseMimeType": "application/json" },
  "pdfSizeBytes": 2114
}
{
  "event": "invoice_receive_ai_unavailable_diagnostic",
  "jobId": "253175",
  "parserErrorName": "InvoiceReceiveAiParserError",
  "causes": [{ "name": "InvoiceAiAgentError", "code": "provider_error", "message": "Gemini invoice parsing failed" }]
}
```

request の model/schema/config は一見普通に見える。次にどう進めますか？
