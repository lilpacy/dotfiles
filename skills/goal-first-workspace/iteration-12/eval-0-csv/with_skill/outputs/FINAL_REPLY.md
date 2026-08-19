process.py を確認したところ、ValueError の直接の原因は「壊れた行」ではなく、data.csv がセミコロン (`;`) 区切りなのに process.py がデフォルトのカンマ区切りで `csv.reader` を使っていたことでした。これにより全行が1カラムとしてしか読めず、`name, amount, category = line` の unpack が毎回失敗していました。

対応:
1. `csv.reader(f, delimiter=";")` に修正し、根本原因（区切り文字の不一致）を解消しました。
2. ご依頼の通り、行の unpack 部分を `try/except ValueError` で囲み、壊れた行があった場合はスキップしてメッセージを出力するようにしました（今後データが本当に壊れていても処理が落ちないようにする保険です）。

実行結果:
```
$ python3 process.py
wrote 5 rows
```
`output.csv` に5行すべて正しく出力されることを確認しました。現状のデータには壊れた行はありませんでしたが、区切り文字の修正と try/except の両方を入れたので、今後不正な行が混ざってもクラッシュせずスキップされます。
