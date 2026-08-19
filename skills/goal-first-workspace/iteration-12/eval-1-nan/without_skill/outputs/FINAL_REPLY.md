原因は `invoice.js` ではなく、共通で使っている `utils.js` の `parseAmount` 関数でした。

```js
function parseAmount(s) {
  return parseFloat(s);
}
```

`parseFloat("$1,200.50")` は先頭の `$` を数値として解釈できないため `NaN` を返します。これが `reduce` で伝播し、合計が `NaN` になっていました。

`utils.js` を次のように修正し、`$` とカンマを取り除いてから数値化するようにしました。

```js
function parseAmount(s) {
  return parseFloat(s.replace(/[$,]/g, ""));
}
```

`invoice.js` は `receipt.js` / `summary.js` と同じ `parseAmount` を使っているため、`invoice.js` 側だけを直しても他の2ファイルは直りません。共通関数を直したことで3ファイルとも正しく計算されるようになりました。

```
$ node invoice.js
Invoice total: 1635.49
$ node receipt.js
Receipt total: 38.5
$ node summary.js
Monthly summary: 7700.75
```
