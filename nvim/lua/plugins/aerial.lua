return {
  "stevearc/aerial.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  ft = { "markdown" },
  keys = {
    { "<leader>o", "<cmd>AerialToggle!<cr>", desc = "Toggle Outline (ToC)" },
  },
  config = function()
    require("aerial").setup({
      backends = { "treesitter", "markdown" },
      layout = {
        min_width = 30,
        default_direction = "right",
      },
      filter_kind = false,
      show_guides = true,
      guides = {
        mid_item = "├─",
        last_item = "└─",
        nested_top = "│ ",
        whitespace = "  ",
      },
      markdown = {
        update_delay = 100,
      },
    })

    -- Markdownファイルを開いた時、画面が広ければ自動でアウトラインを表示
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "markdown",
      callback = function()
        if vim.o.columns >= 120 then
          vim.defer_fn(function()
            local aerial = require("aerial")
            if not aerial.is_open() then
              aerial.open()
            end
          end, 100)
        end
      end,
    })
  end,
}
