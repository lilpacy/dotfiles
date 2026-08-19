invoice.js の合計が NaN になっていたのは、utils.js の parseAmount 関数が通貨フォーマット（ドル記号と カンマ）を処理していなかったため。parseFloat() は "$1,200.50" をパースできないので NaN を返していました。

修正：utils.js の parseAmount 関数を変更し、`s.replace(/[$,]/g, "")` でドル記号とカンマを削除してから parseFloat() する。

実行結果：`node invoice.js` で "Invoice total: 1635.49" と正しく表示されることを確認しました。
