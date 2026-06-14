---
name: absolute-rules
description: Use by any agent before writing specs, editing code, or changing workflow files when the change could add compatibility behavior, aliases, silent fallbacks, or default-value fallbacks.
---

- 後方互換、互換性、エイリアスが明示的に必要とされていない限り、後方互換のための実装は絶対に行わない。明示的に求められない限りは必ず、実装をよりシンプルでクリーンにするための後方互換を残さない破壊的変更を行う。破壊的変更を行う際は、歴史的経緯を思わせるような痕跡すら完全に抹消する。初めからそうであったかのようにコードベースを変更する。
- 明示的な要求がない限り、互換レイヤ・silent fallback・場当たり的な代替経路を追加しないこと。
- fallback は原則的に禁止。failing fast を心がけること。安全に継続できない場合は、明確なエラーを raise すること。`os.getenv()` などにデフォルト引数を入れてフォールバックするのも厳禁。
