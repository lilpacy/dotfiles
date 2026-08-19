直しました。原因は `invoice.js` ではなく `utils.js` の `parseAmount` でした。

`parseFloat("$1,200.50")` は先頭の `$` で即座に解析失敗して `NaN` を返します。`reduce` の合計に一度 `NaN` が混ざると全体が `NaN` になるため、合計が `NaN` に見えていました。

修正は `utils.js` の1箇所だけです。

```js
function parseAmount(s) {
  const n = parseFloat(String(s).replace(/[^\d.-]/g, ""));
  if (Number.isNaN(n)) throw new TypeError(`parseAmount: 解析できません: ${JSON.stringify(s)}`);
  return n;
}
```

通貨記号とカンマを落としてから解析し、それでも数値にならない入力は黙って `NaN` を返さず例外にしました。今後は「合計が `NaN`」ではなく、どの入力が悪いのかがそのまま出ます。

`parseAmount` は `receipt.js` と `summary.js` からも呼ばれていて、同じ理由で両方 `NaN` になっていました。`invoice.js` 側にガードを入れる修正だと残り2つは壊れたままなので、共有関数側で直しています。実行結果です。

```
Invoice total: 1635.49
Receipt total: 38.5
Monthly summary: 7700.75
```

補足として、金額を浮動小数点で扱っている点は今回そのままにしました。この規模の桁数なら誤差は出ませんが、加算を重ねる会計処理に育てるなら整数（セント単位）か decimal ライブラリへの移行を検討してください。
