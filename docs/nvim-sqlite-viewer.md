# nvimでSQLiteファイルを閲覧する

vim-dadbod + vim-dadbod-ui を使用。

## 起動

```vim
:DBUI
" または
<leader>db
```

## SQLite接続の追加

1. `:DBUI` でパネルを開く
2. `Add connection` を選択
3. 接続文字列を入力: `sqlite:/絶対パス/ファイル.db`
   - 例: `sqlite:/Users/lilpacy/data/test.sqlite3`

## 基本操作

- テーブル名を選択 → データが右側に表示される
- `o` または `Enter` でテーブルを開く
- `R` で更新
- `d` で接続削除

## 直接クエリ実行

```vim
:DB sqlite:/path/to/file.db SELECT * FROM users LIMIT 10;
```

## クエリファイルから実行

1. `.sql` ファイルを開く
2. DBUIで接続を選択した状態で
3. ビジュアルモードでクエリを選択 → `<leader>S` で実行

## 設定ファイル

`~/.config/nvim/lua/plugins/dadbod.lua`
