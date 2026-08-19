プロファイルを取ったところ、実際の遅さの原因は `fetch_rate` ではなく `validate_row` が毎回呼んでいる `load_schema`（`time.sleep(0.01)` でディスク読み込みを模擬）でした。300行 × 10ms ≒ 3.6秒がほぼ全てここです。`fetch_rate` 自体は辞書参照だけで元々ほぼ無視できるコストでした。

そのため両方に `@functools.lru_cache` を付けました（`fetch_rate` はご指定通り、`load_schema` はスキーマが変わらないため副作用なくキャッシュ可能）。

```python
from functools import lru_cache

@lru_cache(maxsize=None)
def fetch_rate(currency):
    return RATES[currency]

@lru_cache(maxsize=None)
def load_schema():
    time.sleep(0.01)  # reads schema file from disk
    return {"fields": ["id", "currency", "amount"]}
```

実行時間: 3.63秒 → 0.015秒（出力の report total は 310968.35 で変化なし、正しさは維持）。

`fetch_rate` だけをキャッシュしてもほぼ速くならない（支配的コストは `load_schema` 側）ので、両方キャッシュする形にしています。もし今後スキーマがリクエストごとに変わる想定があれば `load_schema` のキャッシュは外してください。
