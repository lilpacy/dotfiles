return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  config = function()
    require("conform").setup({
      -- filetype ごとに使うフォーマッタを指定
      formatters_by_ft = {
        javascript = { "eslint_d", "prettierd", "prettier", stop_after_first = true },
        javascriptreact = { "eslint_d", "prettierd", "prettier", stop_after_first = true },
        typescript = { "eslint_d", "prettierd", "prettier", stop_after_first = true },
        typescriptreact = { "eslint_d", "prettierd", "prettier", stop_after_first = true },
        json = { "prettierd", "prettier", stop_after_first = true },
        jsonc = { "prettierd", "prettier", stop_after_first = true },
        lua = { "stylua" },
      },

      -- 保存時自動フォーマット
      format_on_save = {
        timeout_ms = 5000,
        -- formatter が見つからない場合は LSP の formatting にフォールバック
        lsp_fallback = true,
      },
    })
  end,
}
