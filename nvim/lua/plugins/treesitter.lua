return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    require("nvim-treesitter").setup({
      install_dir = vim.fn.stdpath("data") .. "/site",
    })

    -- パーサーを非同期でインストール（未インストールの場合のみ）
    local parsers = {
      "markdown", "markdown_inline", "lua", "vim", "vimdoc",
      "javascript", "typescript", "tsx", "python", "bash",
      "json", "yaml", "toml", "html", "css", "rust",
    }

    vim.schedule(function()
      require("nvim-treesitter").install(parsers)
    end)

    -- mdx: filetype を markdown.mdx にし、markdown パーサーを割り当て
    vim.filetype.add({ extension = { mdx = "markdown.mdx" } })
    vim.treesitter.language.register("markdown", "markdown.mdx")

    -- Treesitterハイライト・インデントを有効化
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "*",
      callback = function(args)
        pcall(vim.treesitter.start, args.buf)
      end,
    })

    -- Treesitter構文木表示（:InspectTree）
    vim.keymap.set("n", "<leader>ti", vim.treesitter.inspect_tree, { desc = "Treesitter InspectTree" })
  end,
}
