return {
  "folke/snacks.nvim",
  lazy = false,
  priority = 1000,
  ---@type snacks.Config
  opts = {
    styles = {
      snacks_image = {
        keys = {
          q = "close",
          ["<Esc>"] = "close",
        },
      },
    },
    image = {
      enabled = true,
      doc = {
        enabled = true,
        inline = true,
        float = true,
        max_width = 80,
        max_height = 40,
      },
      convert = {
        notify = true,
        mermaid = function()
          local theme = vim.o.background == "light" and "neutral" or "dark"
          return {
            "-i", "{src}",
            "-o", "{file}",
            "-b", "transparent",
            "-t", theme,
            "-s", "{scale}",
          }
        end,
      },
    },
  },
  keys = {
    {
      "<leader>mi",
      function()
        Snacks.image.hover()
      end,
      desc = "Show image at cursor",
    },
  },
}
