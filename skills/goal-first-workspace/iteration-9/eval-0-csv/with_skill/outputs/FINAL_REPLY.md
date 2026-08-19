```
Goal: process.py が data.csv を最後まで処理し、正常な行を output.csv に書き出せる状態にする（壊れた行があっても止まらない）
Done-when: `python3 process.py` が例外なく完走し、output.csv に5行のデータが入る — met
Verified-by: `python3 process.py` → `wrote 5 rows, skipped 0` / 壊れた行を注入した検証 → `skip line 7: ['frank', 'abc', 'food'] (invalid literal for int() with base 10: 'abc')`, `skip line 8: ['grace', '70'] (not enough values to unpack (expected 3, got 2))`, `wrote 5 rows, skipped 2`
Constraints: 「壊れた行は try/except で skip」→ respected（int変換・アンパック両方を ValueError で捕捉して skip、行番号と理由を stderr に出力）
```

## ご依頼の手段について一点だけ訂正があります

**try/except の skip だけを入れると、5行すべてが skip され output.csv が空になります。**

落ちていた本当の原因は「一部の行が壊れている」ことではなく、**data.csv が セミコロン区切り (`;`) なのに `csv.reader` がデフォルトのカンマ区切りで読んでいた**ことでした。そのため全行が1フィールドとして読まれ、最初の行で即座にアンパックに失敗していました。

```
ValueError: not enough values to unpack (expected 3, got 1)
```

`got 1` が決定的な証拠です。壊れた行なら `got 2` や `got 4` になりますが、`got 1` は「そもそも区切られていない」ことを意味します。この状態で try/except を被せても、エラーは消える代わりに全行が黙って捨てられ、`wrote 0 rows` という一見成功したような出力になります。これは元のクラッシュより厄介です。

## 実際に行った変更

1. **区切り文字の修正（根本原因）** — `csv.reader(f, delimiter=";")`
2. **ご依頼の try/except skip（併せて実装）** — 今後データが増えて実際に壊れた行が来ても止まらないように、ご指示どおり入れてあります

```python
reader = csv.reader(f, delimiter=";")
header = next(reader)
for lineno, line in enumerate(reader, start=2):
    try:
        name, amount, category = line
        rows.append((name, int(amount), category))
    except ValueError as e:
        skipped += 1
        print(f"skip line {lineno}: {line!r} ({e})", file=sys.stderr)
```

skip を無言にしなかった点だけ補足させてください。件数・行番号・理由を stderr に出しています。無言で skip すると「なぜか件数が合わない」という、原因追跡が最も面倒な種類の不具合になります。標準出力のサマリも `wrote 5 rows, skipped 0` として skip 数を常に表示するようにしたので、異常があれば1行で気づけます。

## 動作確認

現状のデータでは5行すべてが正常に処理されます。

```
$ python3 process.py
wrote 5 rows, skipped 0
```

skip 経路が本当に機能するかも、壊れた行（数値でない amount / フィールド不足）を一時的に注入して確認済みです。両方とも意図どおり skip され、正常な5行は残りました（確認後、data.csv は元に戻してあります）。

## ひとつご確認

data.csv がセミコロン区切りなのは意図的でしょうか。エクスポート元の設定（欧州ロケールの Excel などでよく起こります）が原因なら、そちら側をカンマ区切りに直すほうが本筋かもしれません。今回は data.csv を変更せずコード側を合わせてありますが、逆に揃えたい場合はお知らせください。
