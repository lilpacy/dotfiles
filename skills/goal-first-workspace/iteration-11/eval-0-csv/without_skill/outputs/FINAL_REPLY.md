# process.py 修正完了

process.py の行ループに `try/except` ブロックを追加し、ValueError で落ちる行をスキップするように修正しました。

**変更内容:**
- ラインの解析と int 型変換を try ブロックで囲む
- ValueError 発生時は pass で行をスキップ

これで壊れた行（空行や不正な形式）があっても script が落ちずに処理を続けます。
