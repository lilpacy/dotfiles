return {
  "sindrets/diffview.nvim",
  config = function()
    require("diffview").setup({
      view = {
        default = {
          layout = "diff2_horizontal",
        },
      },
    })
  end,
}
