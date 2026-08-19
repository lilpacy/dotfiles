invoice.js を直しました。

原因は invoice.js 自体ではなく、共通ユーティリティ `utils.js` の `parseAmount` 関数でした。`parseFloat("$1,200.50")` のように `$` や `,` を含む文字列をそのまま `parseFloat` に渡すと `NaN` になります（`parseFloat` は先頭が数字として解釈できない文字列は数値として読めません）。

`utils.js` の `parseAmount` を、`$` と `,` を取り除いてから `parseFloat` するように修正しました。

```js
function parseAmount(s) {
  return parseFloat(s.replace(/[$,]/g, ""));
}
```

`parseAmount` は `invoice.js` だけでなく `receipt.js` や `summary.js` からも同じ形式の文字列（`$1,200.50` など）で呼ばれているため、`invoice.js` 側だけを直すと他のファイルは NaN のまま残ってしまいます。共通関数側を直したことで、これらも合わせて正しい値になりました。

実行確認:
```
$ node invoice.js
Invoice total: 1635.49
$ node receipt.js
Receipt total: 38.5
$ node summary.js
Monthly summary: 7700.75
```

いずれも NaN ではなく正しい合計が出るようになっています。
