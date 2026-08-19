計測したところ、遅い原因は `fetch_rate` ではありませんでした。`load_schema` をキャッシュして 3.555s → 0.013s（約273倍）になっています。

## 計測結果（cProfile, 変更前）

```
300    3.545    0.012    3.545  {built-in method time.sleep}   <- load_schema
300    0.000    0.000    0.000  generate_report.py:5(fetch_rate)
```

全体 3.555s のうち `load_schema` が 3.545s（99.7%）でした。`fetch_rate` は `RATES` 辞書を引くだけなので 0.000s、ここをキャッシュしても速くなりません。真犯人は `validate_row` が行ごとに `load_schema` を呼び、300回スキーマを読み直していた点です。

## 変更

```python
@lru_cache(maxsize=1)
def load_schema():
    time.sleep(0.01)  # reads schema file from disk
```

`functools.lru_cache` の1行追加のみ。スキーマは引数を取らず全行で同一なので `maxsize=1` で足ります。

## 検証

| | 変更前 | 変更後 |
|---|---|---|
| 実行時間 | 3.555s | 0.013s |
| report total | 310968.35 | 310968.35 |

`load_schema.cache_info()` は `hits=299, misses=1` で、ディスク読みが300回から1回に減っています。出力は一致しました。

## 注意点

実行中にスキーマファイルを差し替えても再読み込みされません。長時間動くプロセスで書き換えが起きるなら `load_schema.cache_clear()` を明示的に呼ぶ必要があります。バッチ実行なら問題ありません。

`fetch_rate` へのキャッシュ追加は見送りました。`RATES` が将来ネットワーク越しの取得に変わったら、同じ `lru_cache` を足せば済みます。
