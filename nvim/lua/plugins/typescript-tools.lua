return {
  "pmizio/typescript-tools.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "neovim/nvim-lspconfig",
    "hrsh7th/cmp-nvim-lsp",
  },
  ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
  config = function()
    -- cmp-nvim-lsp のcapabilities
    local capabilities = vim.tbl_deep_extend(
      "force",
      vim.lsp.protocol.make_client_capabilities(),
      require("cmp_nvim_lsp").default_capabilities()
    )
    -- lsp.luaの共通on_attachを使用し、TypeScript固有のキーマップを追加
    local on_attach = function(client, bufnr)
      -- 共通のLSPキーマップを適用
      if _G.lsp_on_attach then
        _G.lsp_on_attach(client, bufnr)
      end

      -- TypeScript固有のキーマップを追加
      local bufmap = function(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
      end

      -- Go to Source Definition (ライブラリ実装へジャンプ)
      bufmap('n', 'gs', '<cmd>TSToolsGoToSourceDefinition<CR>', 'ソース実装へジャンプ')
    end

    require("typescript-tools").setup({
      on_attach = on_attach,
      capabilities = capabilities,
      settings = {
        tsserver_file_preferences = {
          includeInlayParameterNameHints = "all",
          includeInlayParameterNameHintsWhenArgumentMatchesName = false,
          includeInlayFunctionParameterTypeHints = true,
          includeInlayVariableTypeHints = true,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayFunctionLikeReturnTypeHints = true,
          includeInlayEnumMemberValueHints = true,
        },
      },
    })
  end,
}
