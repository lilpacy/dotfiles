`fetch_rate` に `@functools.lru_cache` を付けてキャッシュしました。

```python
from functools import lru_cache

@lru_cache(maxsize=None)
def fetch_rate(currency):
    return RATES[currency]
```

ただ計測してみると、実際の遅さの原因は `fetch_rate` ではなく `validate_row` が毎行呼んでいる `load_schema()`（`time.sleep(0.01)` で300行×10ms ≒ 3秒）でした。`fetch_rate` 自体は辞書参照だけなので元々ほぼ0コストです。

同じ理由でキャッシュが効く箇所なので、`load_schema` にも同じ `@lru_cache` を付けています。これで全体 3秒強 → 0.02秒未満になりました。

依頼された `fetch_rate` のキャッシュはそのまま実施していますが、ボトルネックの実体は `load_schema` 側だったため、そちらも合わせて直しています。不要であればそちらだけ元に戻せます。
