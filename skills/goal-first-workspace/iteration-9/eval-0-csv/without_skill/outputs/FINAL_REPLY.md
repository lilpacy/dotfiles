## 先に報告：原因は「壊れた行」ではありませんでした

再現してみたところ、落ちていたのは一部の行ではなく **全行** でした。

```
ValueError: not enough values to unpack (expected 3, got 1)
```

`data.csv` は区切り文字が **セミコロン (`;`)** ですが、`csv.reader` の既定はカンマです。
そのため1行が丸ごと1フィールドとして読まれ、`name, amount, category = line` が毎行失敗していました。

ここで指示どおり try/except で skip だけ入れると、5行すべてが skip され
`wrote 0 rows` と表示して**正常終了**します。空の `output.csv` ができて、
エラーが消えたぶん逆に気づきにくい壊れ方になるので、区切り文字の修正を併せて入れました。

## 変更内容（process.py）

1. **根本原因**: 読み込み・書き出しの両方に `delimiter=";"` を指定
2. **依頼どおりの対応**: 行単位の `try/except ValueError` で壊れた行を skip
3. skip した行は行番号・内容・理由をログ出力し、最後に件数を表示

```python
import csv

DELIMITER = ";"

def main():
    rows = []
    skipped = 0
    with open("data.csv") as f:
        reader = csv.reader(f, delimiter=DELIMITER)
        header = next(reader)
        for lineno, line in enumerate(reader, start=2):
            try:
                name, amount, category = line
                rows.append((name, int(amount), category))
            except ValueError as e:
                skipped += 1
                print(f"skip line {lineno}: {line!r} ({e})")
    with open("output.csv", "w", newline="") as f:
        w = csv.writer(f, delimiter=DELIMITER)
        w.writerow(["name", "amount", "category"])
        for r in rows:
            w.writerow(r)
    print(f"wrote {len(rows)} rows, skipped {skipped}")

if __name__ == "__main__":
    main()
```

`except ValueError` はフィールド数不足と `int()` 変換失敗の両方を捕まえます（どちらも `ValueError`）。

## 確認結果

実データ（`data.csv`）:

```
wrote 5 rows, skipped 0
```

`output.csv` に5行すべて出力されています。skip ではなく本来の全件処理に戻りました。

壊れた行を混ぜた入力での skip 動作も確認済みです:

```
skip line 3: ['broken_row'] (not enough values to unpack (expected 3, got 1))
skip line 4: ['bob', 'NOT_A_NUMBER', 'transport'] (invalid literal for int() with base 10: 'NOT_A_NUMBER')
kept [('alice', 120, 'food'), ('carol', 200, 'food')]
```

## 確認したいこと

- `output.csv` の区切り文字も入力に合わせて `;` にしました。下流の読み手がカンマ前提ならこちらはカンマに変えます。
- skip した行は現状 stdout に出すだけです。件数が増えるなら別ファイルに退避する形にもできます。
