return {
  "MagicDuck/grug-far.nvim",
  keys = {
    -- VSCode style: Cmd+Shift+H for search and replace
    {
      "<C-S-h>",
      function()
        vim.cmd("tab split")
        require("grug-far").open({ transient = true })
        vim.cmd("wincmd o")

        -- 名前なしの未変更バッファをbufferlineから隠す
        local api = vim.api
        for _, bufnr in ipairs(api.nvim_list_bufs()) do
          if api.nvim_buf_is_valid(bufnr) and api.nvim_buf_is_loaded(bufnr) then
            local name = api.nvim_buf_get_name(bufnr)
            local modified = api.nvim_get_option_value("modified", { buf = bufnr })
            if name == "" and not modified then
              api.nvim_set_option_value("buflisted", false, { buf = bufnr })
            end
          end
        end
      end,
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
          extraArgs = "--hidden",  -- 隠しファイル（dotfiles）も検索対象に含める
          placeholders = {
            flags = "e.g. -i (ignore case), -s (case sensitive), -w (whole word), -F (fixed/literal)",
          },
        },
      },
    })
  end,
}
