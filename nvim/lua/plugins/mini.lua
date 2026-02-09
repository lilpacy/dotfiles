return {
  "echasnovski/mini.nvim",
  version = false,
  lazy = false,
  priority = 900,
  config = function()
    require("mini.icons").setup()
    MiniIcons.mock_nvim_web_devicons()

    require("mini.pairs").setup()
    require("mini.surround").setup()
    require("mini.ai").setup()
  end,
}
