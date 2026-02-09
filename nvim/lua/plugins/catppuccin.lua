return {
  "catppuccin/nvim",
  name = "catppuccin",
  lazy = false,
  priority = 1000,
  config = function()
    require("catppuccin").setup({
      flavour = "frappe",
      background = {
        light = "latte",
        dark = "frappe",
      },
      integrations = {
        cmp = true,
        flash = true,
        gitsigns = true,
        mini = { enabled = true },
        native_lsp = { enabled = true },
        neotree = true,
        render_markdown = true,
        snacks = true,
        telescope = { enabled = true },
        treesitter = true,
        trouble = true,
      },
      custom_highlights = function(colors)
        return {
          NeoTreeIndentMarker = { fg = colors.surface1 },
        }
      end,
    })

    vim.cmd.colorscheme("catppuccin")
  end,
}
