return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  config = function()
    require("conform").setup({
      -- filetype ごとに使うフォーマッタを指定
      formatters_by_ft = {
        javascript = { "prettierd", "prettier" },
        javascriptreact = { "prettierd", "prettier" },
        typescript = { "prettierd", "prettier" },
        typescriptreact = { "prettierd", "prettier" },
        json = { "prettierd", "prettier" },
        jsonc = { "prettierd", "prettier" },
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
