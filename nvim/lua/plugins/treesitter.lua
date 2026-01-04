return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  lazy = false,
  config = function()
    require("nvim-treesitter").setup({
      install_dir = vim.fn.stdpath("data") .. "/site",
    })

    -- パーサーをインストール
    require("nvim-treesitter").install({
      "markdown",
      "markdown_inline",
      "lua",
      "vim",
      "vimdoc",
      "javascript",
      "typescript",
      "python",
      "bash",
      "json",
      "yaml",
      "toml",
      "html",
      "css",
    })

    -- Treesitterハイライトを有効化
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "*",
      callback = function(args)
        pcall(vim.treesitter.start, args.buf)
      end,
    })
  end,
}
