# Neovim設定モダナイゼーション計画

2025年時点でのモダンNeovimエコシステムに対応するための改善計画。

## 現状の構成

- Neovim 0.11+
- lazy.nvim (プラグインマネージャー)
- nvim-lspconfig + mason + typescript-tools.nvim (LSP)
- nvim-cmp (補完)
- nvim-tree (ファイラー)
- telescope.nvim v0.2.0固定 (ファジーファインダー)
- gitsigns.nvim (Git)
- conform.nvim (フォーマット)
- bufferline.nvim + lualine.nvim (UI)
- aerial.nvim (アウトライン)
- grug-far.nvim (検索置換)
- snacks.nvim (画像表示)
- treesitter (シンタックス)

## 優先度高: すぐ対応すべき項目

### 1. Treesitter設定の最適化

**現状の問題:**
- `lazy = false` で起動時に全体ロード
- `vim.g._ts_force_sync_parsing = true` で同期パース強制
- 毎回 `require("nvim-treesitter").install()` が走る

**推奨構成:**
```lua
return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },  -- イベントロードに変更
  main = "nvim-treesitter.configs",
  opts = {
    ensure_installed = { "lua", "typescript", "tsx", "json", "markdown", "markdown_inline" },
    highlight = { enable = true },
    indent = { enable = true },
    incremental_selection = { enable = true },
  },
}
```

**効果:** 起動時間短縮、パフォーマンス改善

### 2. Telescope v0.2.0固定の解除

**現状の問題:**
- `tag = "v0.2.0"` で古いバージョンに固定
- バグ修正やパフォーマンス改善を受けられない

**推奨:**
```lua
return {
  "nvim-telescope/telescope.nvim",
  branch = "0.1.x",  -- または tag を削除して最新追従
  -- ...
}
```

### 3. スニペットエンジンの追加

**現状の問題:**
- nvim-cmpにスニペット連携がない
- JS/TS/Luaでの補完体験が限定的

**推奨構成:**
```lua
-- LuaSnipの追加
{
  "L3MON4D3/LuaSnip",
  dependencies = { "rafamadriz/friendly-snippets" },
  build = "make install_jsregexp",
},

-- cmp.luaの修正
{
  "hrsh7th/nvim-cmp",
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "saadparwaiz1/cmp_luasnip",  -- 追加
  },
  config = function()
    local cmp = require("cmp")
    local luasnip = require("luasnip")
    require("luasnip.loaders.from_vscode").lazy_load()

    cmp.setup({
      snippet = {
        expand = function(args) luasnip.lsp_expand(args.body) end,
      },
      sources = cmp.config.sources({
        { name = "nvim_lsp" },
        { name = "luasnip" },  -- 追加
        { name = "buffer" },
        { name = "path" },
      }),
      -- ...
    })
  end,
}
```

### 4. mini.nvim系の導入検討

**推奨モジュール:**
- `mini.pairs` - 括弧のオートペア
- `mini.surround` - surround操作
- `mini.ai` - 拡張テキストオブジェクト

```lua
{
  "echasnovski/mini.nvim",
  version = false,
  config = function()
    require("mini.pairs").setup()
    require("mini.surround").setup()
    require("mini.ai").setup()
  end,
}
```

## 優先度中: 余裕があれば対応

### 5. ファイラーの移行検討

| 選択肢 | 特徴 |
|--------|------|
| neo-tree.nvim | Git/LSP統合度高、安定性重視 |
| snacks.explorer | 既存snacks.nvimと統合可能 |

### 6. trouble.nvim v3の導入

診断・参照・Quickfix結果を統一UIで表示。

```lua
{
  "folke/trouble.nvim",
  opts = {},
  cmd = "Trouble",
  keys = {
    { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
    { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics" },
    { "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols (Trouble)" },
  },
}
```

### 7. flash.nvimの導入

画面内移動の高速化。

```lua
{
  "folke/flash.nvim",
  event = "VeryLazy",
  opts = {},
  keys = {
    { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
    { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
  },
}
```

### 8. which-key.nvimの導入

キーマップのヘルプ表示。

```lua
{
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {},
}
```

### 9. セッション管理の追加

```lua
{
  "folke/persistence.nvim",
  event = "BufReadPre",
  opts = {},
  keys = {
    { "<leader>qs", function() require("persistence").load() end, desc = "Restore Session" },
    { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
  },
}
```

### 10. テスト/デバッグ環境

```lua
-- neotest
{
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "nvim-neotest/neotest-jest",  -- JS/TS用
  },
}

-- nvim-dap
{
  "mfussenegger/nvim-dap",
  dependencies = {
    "rcarriga/nvim-dap-ui",
    "jay-babu/mason-nvim-dap.nvim",
  },
}
```

## パフォーマンス改善ポイント

### 自動保存イベントの最適化

**現状:** InsertLeave, TextChanged, CursorHold, BufLeave, FocusLost 全てで保存

**推奨:** InsertLeave + TextChanged に絞る（I/O削減）

### フォーマット二重処理の回避

**現状:** conform.nvim + ESLint LSP が両方動作

**推奨:**
- フォーマットは conform.nvim (prettierd) に一本化
- LSPのformattingProviderは無効化

```lua
vim.lsp.config('eslint', {
  capabilities = {
    documentFormattingProvider = false,
  },
})
```

## 現状維持で良い項目

| プラグイン | 理由 |
|------------|------|
| nvim-cmp | 安定性が高い（blink.cmpはまだ発展途上） |
| typescript-tools.nvim | 良い選択、継続推奨 |
| conform.nvim | none-ls/lsp-zeroより現構成が良い |
| aerial.nvim | モダンで問題なし |
| gitsigns.nvim | 定番で安定 |
| bufferline.nvim | 問題なし |
| lualine.nvim | 問題なし |

## 実装順序の推奨

1. **Phase 1:** Treesitter最適化 + Telescope pin解除
2. **Phase 2:** LuaSnip追加
3. **Phase 3:** mini.nvim導入
4. **Phase 4:** trouble.nvim / flash.nvim / which-key.nvim
5. **Phase 5:** ファイラー移行検討
6. **Phase 6:** neotest / nvim-dap

## 参考リンク

- [mini.nvim](https://github.com/echasnovski/mini.nvim)
- [neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim)
- [trouble.nvim](https://github.com/folke/trouble.nvim)
- [flash.nvim](https://github.com/folke/flash.nvim)
- [persistence.nvim](https://github.com/folke/persistence.nvim)
- [blink.cmp](https://github.com/saghen/blink.cmp) (将来の検討用)
