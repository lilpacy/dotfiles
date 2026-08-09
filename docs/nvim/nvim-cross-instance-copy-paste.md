# Neovim で別インスタンス間のフォルダコピペを実現する方法

NvimTree単体では別のNeovimインスタンス（別ウィンドウ）間でフォルダをコピー＆ペーストできない。
VSCodeのような体験を実現する方法をまとめる。

## 方法1: Neo-tree に乗り換える（推奨）

Neo-treeの `clipboard.sync = "universal"` を使うと、JSONファイル経由でマシン上のすべてのNeo-tree間でクリップボードを共有できる。

### インストール・設定

```lua
-- lua/plugins/neo-tree.lua
return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  config = function()
    require("neo-tree").setup({
      clipboard = {
        sync = "universal",  -- インスタンス間でクリップボード共有
      },
      -- 他の設定はお好みで
    })
  end,
  keys = {
    { "<C-n>", "<cmd>Neotree toggle<CR>", desc = "Toggle Neo-tree" },
  },
}
```

### 操作方法

| キー | 動作 |
|------|------|
| `y` | コピー（copy_to_clipboard） |
| `x` | カット（cut_to_clipboard） |
| `p` | ペースト（paste_from_clipboard） |

1. Neovim A の Neo-tree でフォルダにカーソルを合わせて `y` または `x`
2. Neovim B の Neo-tree で貼り付け先にカーソルを合わせて `p`

## 方法2: NvimTree + remote-ui（1プロセス複数UI）

Neovimの `--listen` / `--remote-ui` を使うと、見た目は別ウィンドウでも内部的には同一インスタンスになり、NvimTreeのクリップボードが共有される。

### 使い方

```bash
# ターミナル1（サーバー起動）
nvim --listen ~/.cache/nvim/server.pipe

# ターミナル2（クライアント接続）
nvim --server ~/.cache/nvim/server.pipe --remote-ui
```

これで2つのターミナルに別々のNeovim UIが表示されるが、実体は1プロセス。
NvimTreeの `c`（コピー）/ `x`（カット）/ `p`（ペースト）が共有される。

### エイリアス設定（任意）

```bash
# ~/.zshrc
alias nvim-server='nvim --listen ~/.cache/nvim/server.pipe'
alias nvim-client='nvim --server ~/.cache/nvim/server.pipe --remote-ui'
```

## 方法3: パスコピー + cp コマンド

NvimTreeの `gy` でパスをシステムクリップボードにコピーし、別nvimでシェルコマンドを実行する。

### 操作手順

1. 元のNvimTreeでフォルダ上で `gy`（絶対パスをクリップボードにコピー）
2. 別のNeovimで以下を実行:
   ```vim
   :!cp -r "<C-r>+" .
   ```

### ショートカット設定（任意）

```lua
-- nvim-tree.lua の on_attach 内に追加
vim.keymap.set('n', 'Y', api.fs.copy.absolute_path, opts('Copy absolute path'))
```

```lua
-- keymaps.lua などに追加
vim.keymap.set('n', '<leader>P', ':!cp -r "<C-r>+" .<CR>', { desc = 'Paste folder from clipboard path' })
```

## 比較

| 方法 | メリット | デメリット |
|------|----------|------------|
| Neo-tree | VSCodeに最も近い体験 | プラグイン乗り換えが必要 |
| remote-ui | NvimTree継続可能 | プロセス分離ができない |
| パス+cp | シンプル、設定不要 | 手動操作が多い |

## 参考

- [neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim)
- [nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua)
- [Neovim remote UI](https://neovim.io/doc/user/remote.html)
