# Neovim Mermaid図の大画面フロート表示

`<leader>mi`でMermaid図を画面いっぱいに表示する機能。インライン表示は通常サイズを維持しつつ、手動表示時のみ大きく表示します。

## 概要

`snacks.nvim`のimage機能を使用して、Mermaid図を2つのモードで表示できます：
- **インライン表示**: ドキュメント内で通常サイズ（120x60）で自動表示
- **手動フロート表示**: `<leader>mi`で画面いっぱいに表示

## 使い方

### Mermaid図の大画面表示

**キーマップ**: `<leader>mi`

Mermaid図のコードブロック上で`<leader>mi`を押すと、画面サイズに合わせて図を大きく表示します。

**使い方**:
1. Mermaid図のコードブロック上にカーソルを移動
2. `<leader>mi`を押下
3. 画面いっぱいにMermaid図がフロート表示される
4. `q`または`<Esc>`で閉じる

**利点**:
- 複雑なMermaid図を大きく確認できる
- インライン表示は通常サイズを維持
- 端末のサイズに自動適応

## 実装詳細

設定ファイル: `/Users/lilpacy/dotfiles/nvim/lua/plugins/snacks.lua`

### 技術的な背景

`Snacks.image.hover()`は引数でオプションを渡しても無視され、常に`Snacks.image.config.doc`のグローバル設定を使用します。そのため、以下のような実装では動作しません：

```lua
-- ❌ これは動作しない
Snacks.image.hover({
  max_width = 300,
  max_height = 200,
})
```

### 解決策

グローバル設定を一時的に書き換え、表示後に元に戻す方法を採用しています：

```lua
keys = {
  {
    "<leader>mi",
    function()
      local img = require("snacks.image")
      local doc = img.config.doc

      -- 現在の値を退避
      local old_w, old_h = doc.max_width, doc.max_height

      -- 手動表示のときだけ画面いっぱいに
      doc.max_width  = vim.o.columns       -- 端末の列数
      doc.max_height = vim.o.lines - 2     -- 端末の行数から少し余白

      Snacks.image.hover()

      -- 元に戻す（インライン表示用に 120x60 を維持）
      doc.max_width, doc.max_height = old_w, old_h
    end,
    desc = "Show image at cursor (large)",
  },
},
```

### 動作の流れ

1. 現在の`max_width`と`max_height`（120x60）を退避
2. グローバル設定を画面サイズに書き換え
   - `vim.o.columns`: 端末の列数
   - `vim.o.lines - 2`: 端末の行数から余白を引く
3. `Snacks.image.hover()`を呼び出し
4. 即座に元の設定（120x60）に戻す

この方法により、インライン表示は通常サイズを維持しつつ、手動表示時のみ大画面表示を実現しています。

## 設定のカスタマイズ

### 画面サイズの調整

画面いっぱいすぎる場合は、以下のように固定値に変更できます：

```lua
-- 画面サイズではなく固定値を使用
doc.max_width  = 200  -- 好みの幅
doc.max_height = 80   -- 好みの高さ
```

### インライン表示サイズの変更

通常のインライン表示サイズを変更したい場合は、`opts.image.doc`の設定を変更します：

```lua
opts = {
  image = {
    doc = {
      max_width = 120,   -- インライン表示の幅
      max_height = 60,   -- インライン表示の高さ
    },
  },
},
```

## Tips

- **端末サイズに適応**: 端末のサイズを変更しても、常に画面サイズに合わせて表示されます
- **インライン表示との併用**: 通常はインラインで確認し、詳細を見たい時だけ`<leader>mi`を使用
- **複雑な図の確認**: ノード数の多いMermaid図やシーケンス図の確認に便利

## トラブルシューティング

### サイズが変わらない

- Neovimを再起動するか`:Lazy reload snacks.nvim`で設定を再読み込み
- `Snacks.image.hover()`に直接オプションを渡していないか確認（動作しません）

### 画面からはみ出る

- `doc.max_width`や`doc.max_height`の値を小さくする
- 端末サイズを広げる

### Mermaid図が表示されない

- Mermaid CLIがインストールされているか確認: `mmdc --version`
- Mermaid図のコードブロックが正しいか確認（````mermaid`で開始）
- `:Snacks profile`でsnacks.nvimが正しく読み込まれているか確認

## 参考情報

- [snacks.nvim image module](https://github.com/folke/snacks.nvim)
- 問題の原因: `Snacks.image.hover()`の実装が引数のオプションを無視する設計
