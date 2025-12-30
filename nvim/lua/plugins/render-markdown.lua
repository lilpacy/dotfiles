return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  ft = { "markdown" },
  opts = {
    heading = {
      enabled = true,
      icons = { "# ", "## ", "### ", "#### ", "##### ", "###### " },
      backgrounds = {
        "RenderMarkdownH1Bg",
        "RenderMarkdownH2Bg",
        "RenderMarkdownH3Bg",
        "RenderMarkdownH4Bg",
        "RenderMarkdownH5Bg",
        "RenderMarkdownH6Bg",
      },
    },
    code = {
      enabled = true,
      style = "full",
      border = "thin",
    },
    bullet = {
      enabled = true,
      icons = { "●", "○", "◆", "◇" },
    },
    checkbox = {
      enabled = true,
      unchecked = { icon = "☐ " },
      checked = { icon = "☑ " },
    },
    link = {
      enabled = true,
      image = "󰥶 ",
      hyperlink = "󰌹 ",
    },
  },
}
