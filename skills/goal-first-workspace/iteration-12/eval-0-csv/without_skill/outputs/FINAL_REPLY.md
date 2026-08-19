# process.py の ValueError 修正

## 原因

`ValueError: not enough values to unpack (expected 3, got 1)` の本当の原因は、`data.csv` の区切り文字が `;`（セミコロン）なのに、`process.py` の `csv.reader(f)` がデフォルトの `,`（カンマ）で読んでいたことでした。そのため全行が1カラムとして読み込まれ、`name, amount, category = line` の代入が全行で失敗していました。「一部の行だけ壊れている」のではなく、区切り文字の指定ミスで全行が「壊れている」ように見えていた状態です。

## 対応

1. `csv.reader(f, delimiter=";")` に修正し、正しい区切り文字で読み込むようにしました。
2. ご要望の通り、行の unpack や型変換で `ValueError` が出た場合は `try/except ValueError` で捕捉し、その行だけスキップして処理を継続するようにしました（スキップ時はどの行を捨てたかログ出力します）。

これで区切り文字ミス以外の理由（列数が足りない、`amount` が数値に変換できない等）で壊れている行があっても、そこだけスキップして残りの行は正常に `output.csv` に出力されます。

## 動作確認

`python3 process.py` を実行し、`wrote 5 rows` と表示され、`output.csv` に5行すべて正しく出力されることを確認しました。
