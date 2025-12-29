return {
  "MagicDuck/grug-far.nvim",
  keys = {
    -- VSCode style: Cmd+Shift+H for search and replace
    {
      "<C-S-h>",
      function() require("grug-far").open({}) end,
      desc = "Search & Replace (Cmd+Shift+H)",
    },
    {
      "<leader>sr",
      function() require("grug-far").open({}) end,
      desc = "Search & Replace",
    },
    -- カーソル下の単語で検索
    {
      "<leader>sw",
      function()
        require("grug-far").open({
          prefills = { search = vim.fn.expand("<cword>") },
        })
      end,
      desc = "Search & Replace current word",
    },
    -- ビジュアル選択で検索
    {
      "<leader>sw",
      function()
        require("grug-far").with_visual_selection({})
      end,
      mode = "v",
      desc = "Search & Replace selection",
    },
    -- 現在のファイル内で検索＆置換
    {
      "<leader>sf",
      function()
        require("grug-far").open({
          prefills = { paths = vim.api.nvim_buf_get_name(0) },
        })
      end,
      desc = "Search & Replace in current file",
    },
  },
  config = function()
    require("grug-far").setup({
      -- デフォルト設定で十分、必要に応じてカスタマイズ
    })
  end,
}
