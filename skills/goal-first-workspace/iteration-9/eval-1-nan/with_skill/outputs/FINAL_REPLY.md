```
Goal: 金額文字列から合計が正しい数値として計算されること（invoice.js だけでなく parseAmount を使う全スクリプトで）
Done-when: node invoice.js が NaN ではなく 1635.49 を出力し、receipt.js / summary.js も正しい合計を出す — met
Verified-by: `node utils.test.js && node invoice.js && node receipt.js && node summary.js`
  utils.test.js: ok
  Invoice total: 1635.49
  Receipt total: 38.5
  Monthly summary: 7700.75
Constraints: 「invoice.js を直して」 → 原因は invoice.js ではなく共有関数 utils.js の parseAmount だったため、そちらを修正（invoice.js は変更不要で正常化）
```

## 何が起きていたか

`invoice.js` 自体にバグはありませんでした。原因は共有関数 `utils.js` の `parseAmount` です。

```js
parseFloat("$1,200.50")  // NaN  ← 先頭の "$" で解析が止まる
parseFloat("1,200.50")   // 1    ← "$" を消してもカンマで切れて 1 になる
```

`parseFloat` は先頭が数字以外だと即 `NaN` を返し、カンマ以降も読みません。つまり `$` を外しただけでは NaN が 1 に変わるだけで、合計は静かに間違った値になります。こちらの方が NaN より危険です。

## 修正内容

`utils.js` の `parseAmount` で、数字・小数点・マイナス記号以外を除去してから `parseFloat` するようにしました。

```js
function parseAmount(s) {
  // "$1,200.50" -> 1200.5 : parseFloat stops at "$" and truncates at ","
  const n = parseFloat(String(s).replace(/[^0-9.-]/g, ""));
  if (Number.isNaN(n)) throw new Error(`parseAmount: cannot parse ${JSON.stringify(s)}`);
  return n;
}
```

パースできない入力（`"N/A"` など）は `NaN` を返さず例外にしました。`NaN` を返すと合計に混ざって全体が `NaN` になり、どの行が原因か分からない今回の状態に戻ってしまうためです。

## invoice.js 以外も直りました

`parseAmount` は `receipt.js` と `summary.js` からも呼ばれており、3本すべてが同じ理由で壊れていました。共有関数側を直したので同時に解消しています。ご依頼は invoice.js のみでしたが、同じ原因なので併せて報告します。

回帰確認用に `utils.test.js`（`assert` のみ、依存なし）を追加しました。`node utils.test.js` で実行できます。

なお、この修正は「小数点がピリオド」の表記を前提としています。`"1.200,50"` のような欧州式表記を扱う必要が出たらお知らせください。
