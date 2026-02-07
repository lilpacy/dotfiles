return {
  "hedyhli/outline.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "epheien/outline-treesitter-provider.nvim",
  },
  cmd = { "Outline", "OutlineOpen" },
  keys = {
    { "<leader>O", "<cmd>Outline<cr>", desc = "Toggle Outline (JSX/DOM)" },
  },
  opts = {
    outline_window = {
      position = "right",
      width = 30,
      relative_width = false,
    },
    guides = {
      enabled = true,
    },
    symbol_folding = {
      autofold_depth = false, -- 全階層展開で開始
      auto_unfold = {
        hovered = false,
        only = false,
      },
    },
    outline_items = {
      auto_set_cursor = false,
    },
    symbols = {
      filter = nil, -- すべてのシンボルを表示
    },
    providers = {
      priority = { "treesitter", "lsp", "markdown" },
    },
    keymaps = {
      goto_location = { "<CR>", "<LeftRelease>" },
    },
  },
}
