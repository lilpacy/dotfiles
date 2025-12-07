return {
  -- LSP設定
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      -- Masonのセットアップ
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "ts_ls" }, -- 使用する言語に応じて追加
        automatic_installation = true,
      })

      -- LSPキーマッピング
      local on_attach = function(client, bufnr)
        local opts = { buffer = bufnr, noremap = true, silent = true }
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts) -- 定義へジャンプ
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts) -- 宣言へジャンプ
        vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts) -- 実装へジャンプ
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts) -- 参照を表示
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts) -- ホバー情報
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts) -- リネーム
      end

      -- LSPサーバーの設定
      local lspconfig = require("lspconfig")
      lspconfig.lua_ls.setup({ on_attach = on_attach })
      lspconfig.ts_ls.setup({ on_attach = on_attach })
      -- 他の言語サーバーも同様に追加
    end,
  },
}
