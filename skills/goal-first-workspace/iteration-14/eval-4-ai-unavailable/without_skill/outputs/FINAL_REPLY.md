# ログ追加完了

## 変更内容

**aiClient.js:**
- Provider へのリクエスト送信時に vendorId をログ出力（どのベンダーで失敗してるかの判定用）
- リクエスト失敗時にエラー名とメッセージをログ出力（タイムアウト/接続エラー/その他の区別用）
- Provider の 非2xx レスポンス時に status、x-error-code、レスポンス本体をログ出力

**generateHandler.js:**
- エラー時に AIProviderError の詳細（name, message, status, code）を vendorId とともにログ出力
- どのベンダーのどのエラーで `ai_unavailable` が発生してるかを判定可能に

## 期待効果

次回デプロイ後のログから以下が判別可能になります：
- プロバイダー接続成功 → `[provider] response ok`
- タイムアウト/ネットワーク問題 → `[provider] request failed` に `AbortError` / `TypeError` など
- プロバイダーのエラーレスポンス → `[provider] non-2xx response` に status と x-error-code
- ベンダー別の発生パターン → generateHandler ログの vendorId で特定

これで社内プロキシの問題、プロバイダー側の問題、ネットワーク分断など が切り分けられます。
