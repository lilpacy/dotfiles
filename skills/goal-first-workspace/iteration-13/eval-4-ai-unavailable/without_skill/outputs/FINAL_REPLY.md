## 対応内容

`generateHandler.js` の catch 節に、切り分け用のログを追加しました。

現状のログは `generate failed: ai_unavailable` のみで、`errors.js` の `normalizeError` が
「provider への疎通失敗」「provider が非2xxを返した」「タイムアウト」を全部 `ai_unavailable` に
畳んでしまうため、staging のログだけでは原因（proxy 側の疎通問題か、provider 側のエラーか、
タイムアウトか）が分かりませんでした。

追加したログでは、元エラー（`AIProviderError`）が持っている情報をそのまま出力します。

- `err.status` — provider からの HTTP ステータス（非2xxの場合。疎通失敗なら `undefined`）
- `err.code` — provider が付与する `x-error-code` ヘッダの値
- `err.cause` — 実際の失敗理由（`fetch` の例外 = ネットワーク/タイムアウト、または provider が返した
  レスポンスボディの先頭2000文字）

これで次に `ai_unavailable` が出たときに、ログを見るだけで

- `cause.name` が `TimeoutError` / `AbortError` → タイムアウト（15秒）→ proxy or provider が遅い
- `status` が入っていて非2xx → provider 側がエラーを返している（`code` も併せて見る）
- `cause` のみで `status` が空 → provider に到達できていない（proxy 疎通の問題を疑う）

の3パターンを切り分けられます。CI 経由の反映で1往復1〜2時間かかるとのことなので、次の staging 反映後に
ログを確認してください。ローカルで再現しない点も踏まえると、proxy 経由の疎通かタイムアウトの可能性が高いと
見ていますが、ログの内容で確定させましょう。

## 変更ファイル

- `generateHandler.js`: catch 節のログに `status` / `code` / `cause` を追加（挙動・レスポンスは変更なし）
