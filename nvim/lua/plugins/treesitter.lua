return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    local ts = require("nvim-treesitter")

    ts.setup({
      ensure_install = {
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
      },
    })

    vim.treesitter.language.register("markdown", "markdown")
  end,
}
