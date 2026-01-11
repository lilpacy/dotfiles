# Neovim Git差分プレビュー機能

VSCodeのように、変更があった行で簡単に差分を表示できる機能。

## 概要

`gitsigns.nvim`を使用して、編集中のファイルのgit差分をインタラクティブに表示できます。3つの方法で差分をプレビューできます。

## 使い方

### 1. Floating Window表示（推奨）

**キーマップ**: `<leader>hp`

カーソル行の変更をフローティングウィンドウで表示します。

**使い方**:
1. 変更があった行にカーソルを移動
2. `<leader>hp`を押下
3. フローティングウィンドウで差分が表示される
4. `q`または`<Esc>`で閉じる

**利点**:
- コード本体を隠さない
- 視認性が高い
- 複数行の変更も見やすい
- TUI/SSH環境でも確実に動作

---

### 2. Inline差分表示（VSCode風）

**キーマップ**: `<leader>hP`（大文字のP）

カーソル行の下に差分を展開表示します。

**使い方**:
1. 変更があった行にカーソルを移動
2. `<leader>hP`を押下
3. カーソル行の下に差分が展開される

**利点**:
- VSCode風の体験
- コンテキストを保ったまま確認可能
- 一瞬の確認に便利

---

### 3. マウスクリック対応

**キーマップ**: `Ctrl+左クリック`

変更行をマウスでクリックして差分を表示します。

**使い方**:
1. 変更があった行を`Ctrl+左クリック`
2. フローティングウィンドウで差分が表示される

**注意**:
- GUI環境（neovide、goneovimなど）向け
- `set mouse=a`が有効な環境で動作
- TUI環境では動作しない場合あり

---

## 既存の機能との関係

### 右クリックメニュー

右クリックメニューの`Git: Preview Hunk`も引き続き使用可能です。新しいキーマップと併用できます。

### Hunkナビゲーション

差分の確認と合わせて、以下のキーマップでhunk間を移動できます:

- `]c` - 次のhunkへ移動
- `[c` - 前のhunkへ移動

## 実装詳細

設定ファイル: `/Users/lilpacy/dotfiles/nvim/lua/plugins/gitsigns.lua`

```lua
-- 差分プレビュー（Floating window）- VSCode風の機能
map('n', '<leader>hp', gs.preview_hunk, { desc = "Git: hunkをプレビュー" })

-- 差分プレビュー（Inline）- カーソル行の下に差分を展開
map('n', '<leader>hP', gs.preview_hunk_inline, { desc = "Git: hunkをインライン表示" })

-- マウスクリック対応（オプション）
map('n', '<C-LeftMouse>', function()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<LeftMouse>', true, false, true), 'n', false)
  pcall(gs.preview_hunk)
end, { desc = "Git: hunkをクリックでプレビュー" })
```

## Tips

- **キーボード派**: `<leader>hp`が最も効率的
- **視覚的確認派**: `<leader>hP`でコンテキストを保持
- **マウス派**: `Ctrl+左クリック`でVSCode風の操作感
- **変更の多いファイル**: `]c`/`[c`でhunk間を移動しながら`<leader>hp`で確認

## トラブルシューティング

### 差分が表示されない

- ファイルがgit管理下にあるか確認
- 実際に変更があるか確認
- gitsigns.nvimが読み込まれているか確認（`:Gitsigns`コマンドが使えるか）

### マウスクリックが効かない

- `set mouse=a`が有効か確認（`:set mouse?`で確認）
- TUI環境では動作しない場合があるため、キーマップの使用を推奨
