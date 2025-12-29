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
    -- 大文字小文字を区別して検索（Case Sensitive）
    {
      "<leader>sC",
      function()
        require("grug-far").open({
          prefills = { flags = "-s" },
        })
      end,
      desc = "Search & Replace (Case Sensitive)",
    },
    -- 単語完全一致（Whole Word）
    {
      "<leader>sW",
      function()
        require("grug-far").open({
          prefills = { flags = "-w" },
        })
      end,
      desc = "Search & Replace (Whole Word)",
    },
    -- リテラル検索（正規表現OFF、VSCodeのRegexボタンOFF相当）
    {
      "<leader>sL",
      function()
        require("grug-far").open({
          prefills = { flags = "-F" },
        })
      end,
      desc = "Search & Replace (Literal/Fixed)",
    },
  },
  config = function()
    require("grug-far").setup({
      -- VSCode風のキーマップ（grug-farバッファ内で使用）
      keymaps = {
        toggleShowCommand = { n = "<localleader>c" },
        toggleFlags = { n = "<localleader>f" },
      },
      -- エンジン別の設定
      engines = {
        ripgrep = {
          placeholders = {
            flags = "e.g. -i (ignore case), -s (case sensitive), -w (whole word), -F (fixed/literal)",
          },
        },
      },
    })
  end,
}
