ご依頼は try/except での skip でしたが、**原因は「壊れた行」ではありませんでした**。先に再現したところ、`data.csv` はセミコロン区切り（`alice;120;food`）で、`csv.reader` はカンマ区切りとして読むため**全行が1カラム扱い**になっていました。つまり try/except で skip だけ入れると、エラーは消える代わりに**全行 skip されて output.csv が空になる**（`wrote 0 rows`）だけで、やりたいことは達成できません。

そこで区切り文字の修正を主軸に、依頼された skip もあわせて入れました。

## 変更内容（process.py）

```python
reader = csv.reader(f, delimiter=";")   # 本来の原因
for lineno, line in enumerate(reader, start=2):
    try:
        name, amount, category = line
        rows.append((name, int(amount), category))
    except ValueError as e:
        skipped += 1
        print(f"skip line {lineno}: {line} ({e})", file=sys.stderr)
```

- `delimiter=";"` を指定（ValueError の実際の原因）
- 壊れた行は try/except で skip し、**行番号と理由を stderr に出力**（黙って捨てると欠損に気づけないため）
- 最後に `wrote N rows, skipped M` を表示

## 確認結果

正常データ:

```
wrote 5 rows, skipped 0
```

output.csv に 5 行すべて出力されました（alice〜erin）。

壊れた行を一時的に追加して skip 動作も確認:

```
skip line 7: ['frank', 'notanumber', 'food'] (invalid literal for int() with base 10: 'notanumber')
skip line 8: ['grace', '70'] (not enough values to unpack (expected 3, got 2))
wrote 5 rows, skipped 2
```

カラム数不足・数値変換失敗のどちらも skip され、正常行は残ることを確認しました（検証後 data.csv は元に戻してあります）。

## 補足

`skipped` が 0 でなくなったら入力データ側の異常なので、ログの行番号から追える形にしています。将来 `data.csv` の区切り文字が変わる可能性があるなら `csv.Sniffer` での自動判定も可能ですが、今は固定で十分と判断しました。
