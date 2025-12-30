return {
  "stevearc/aerial.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  -- ftなし: どのfiletypeでも<leader>oで使える
  keys = {
    { "<leader>o", "<cmd>AerialToggle!<cr>", desc = "Toggle Outline (ToC / Symbols)" },
  },
  config = function()
    require("aerial").setup({
      -- filetypeごとのbackend設定
      backends = {
        _ = { "treesitter", "lsp" },  -- デフォルト（コード全般）
        markdown = { "markdown" },     -- Markdown専用
      },
      layout = {
        min_width = 30,
        max_width = { 40, 0.25 },
        default_direction = "prefer_right",
        placement = "edge",
      },
      attach_mode = "global",  -- VSCodeのOutlineのようにバッファ切り替えに追従
      -- 言語ごとのシンボルフィルタ
      filter_kind = {
        _ = { "Class", "Constructor", "Enum", "Function", "Interface", "Module", "Method", "Struct" },
        markdown = { "Interface" },  -- 見出しのみ
      },
      show_guides = true,
      guides = {
        mid_item = "├─",
        last_item = "└─",
        nested_top = "│ ",
        whitespace = "  ",
      },
    })
  end,
}
