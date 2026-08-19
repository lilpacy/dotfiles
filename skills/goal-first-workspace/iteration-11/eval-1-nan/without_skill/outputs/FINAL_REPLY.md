# 修正完了

invoice.js の NaN 問題を修正しました。

## 問題
`parseAmount()` 関数が `parseFloat()` を直接使用していたため、`"$1,200.50"` のような通貨記号とカンマ付きの文字列をパースできていませんでした。`parseFloat()` は最初の非数値文字（この場合 `$`）で停止するため NaN を返していました。

## 修正
utils.js の `parseAmount()` 関数を修正し、パースする前に通貨記号 `$` とカンマ `,` を削除するようにしました。

```javascript
return parseFloat(s.replace(/[$,]/g, ""));
```

## 結果
実行結果：`Invoice total: 1635.49`（正しい合計が出力されるようになりました）
