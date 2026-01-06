# CRLF/BOM問題のトラブルシューティング

## 改行コードの違い

| OS | 改行コード | バイト | 表記 |
|----|-----------|--------|------|
| Windows | CRLF | `\r\n` (0D 0A) | CR + LF |
| Mac/Linux | LF | `\n` (0A) | LF のみ |

`^M` = `\r` = CR（キャリッジリターン）

## BOM（Byte Order Mark）とは

ファイルの先頭に付ける目印で、「このファイルはUTF-8」と示すためのもの。

- 見えない3バイト: `EF BB BF`（表示上は `﻿`）
- Windowsのメモ帳などがUTF-8保存時に付ける
- Mac/Linuxでは付けないのが普通

## よくある問題

### grug-farで置換後に^Mが表示される

**原因**: grug-farが^Mを追加しているのではなく、元ファイルにあったCRが残っている。

Windows形式のファイル（例: Tactiq.ioのトランスクリプト）を置換すると：
- ripgrepは改行変換をしない
- 元の行末にあったCR（`\r`）がそのまま残る
- git diffで見ると `+行内容^M` と表示される

## 解決策

### 方法1: Neovimで手動修正

```vim
" 行末CRを除去
:%s/\r$//e

" 改行形式をLFに統一
:setlocal ff=unix

" BOMも除去（必要なら）
:setlocal nobomb

" 保存
:w
```

### 方法2: Neovimで自動変換（autocmd）

`~/.config/nvim/lua/config/options.lua` に追加:

```lua
-- CRLF/CRを自動的にLFに変換
vim.api.nvim_create_autocmd("BufReadPost", {
  pattern = "*",
  callback = function()
    local lines_with_cr = vim.fn.search('\\r$', 'nw')
    if lines_with_cr > 0 then
      vim.cmd([[silent! %s/\r$//e]])
      vim.bo.fileformat = "unix"
      vim.bo.bomb = false
    end
  end,
  desc = "CRLF/CRを自動的にLFに変換"
})
```

### 方法3: CLIで一括変換

```sh
brew install dos2unix
dos2unix path/to/file.txt

# 複数ファイル
find . -type f -name '*.txt' -exec dos2unix {} +
```

## 確認方法

### Neovimでファイルの改行形式を確認

```vim
:set ff?        " fileformat確認（unix/dos）
:set ffs?       " fileformats確認
```

### 行末CRの有無をカウント

```vim
:%s/\r$//n      " マッチ数が表示される（置換はされない）
```

### 行末を可視化

```vim
:set list listchars=eol:$,trail:·
```

## 参考

- `vim.opt.fileformat = "unix"` は新規ファイル用の設定
- 既存ファイルのCRは自動削除されない
- grug-far/ripgrepは改行変換ツールではない
