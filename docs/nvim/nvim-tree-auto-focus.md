# nvim-tree 自動フォーカス追従機能

## 概要

nvimで開いているバッファに対して、nvim-treeでも自動的にフォーカスが追従する機能。タブ切り替えやTelescopeからのファイル検索で開いたときに、ツリー上で該当ファイルがハイライトされる。

## 設定

`nvim/lua/plugins/nvim-tree.lua` の `update_focused_file` オプションを使用:

```lua
update_focused_file = {
  enable = true,
  update_root = false, -- ルートディレクトリは変更しない
  exclude = function(event)
    -- event は BufEnter イベントオブジェクト、バッファ番号は event.buf
    local bufnr = event.buf
    if not bufnr or bufnr <= 0 then
      return true
    end
    if not vim.api.nvim_buf_is_valid(bufnr) then
      return true
    end
    local buftype = vim.bo[bufnr].buftype
    -- terminal、nofile、quickfix、promptなどのバッファはスキップ
    return buftype == "nofile" or buftype == "terminal" or buftype == "quickfix" or buftype == "prompt"
  end,
},
```

## トラブルシューティング

### 問題: Telescope起動時にエラーが発生

**症状**: `Invalid 'name': Expected Lua string` や `Invalid 'buffer': Expected Lua number` などのエラー

**原因**: `exclude` 関数の引数を `bufnr`（数値）と想定していたが、実際には `BufEnter` イベントオブジェクト（テーブル）が渡される。

**解決策**: 引数を `event` として受け取り、`event.buf` でバッファ番号を取得する。

nvim-tree ドキュメントより:
> Takes the `BufEnter` event as an argument.

イベントオブジェクトの構造:
- `event.buf` - バッファ番号
- `event.file` - ファイルパス
- `event.event` - イベント名

## 参考

- nvim-tree GitHub: https://github.com/nvim-tree/nvim-tree.lua
- `:help nvim-tree-opts-update_focused_file`
