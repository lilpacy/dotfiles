return {
  "nvim-tree/nvim-tree.lua",
  dependencies = {
    "nvim-tree/nvim-web-devicons", -- アイコン表示用
  },
  config = function()
    require("nvim-tree").setup({
      -- ビューの設定
      view = {
        width = 30,
        side = "left",
      },
      -- マウスサポートを有効化
      on_attach = function(bufnr)
        local api = require('nvim-tree.api')

        -- デフォルトのキーマッピングを適用
        api.config.mappings.default_on_attach(bufnr)

        -- マウスクリックでファイル/フォルダを開く
        vim.keymap.set('n', '<LeftMouse>', function()
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<LeftMouse>', true, false, true), 'n', false)
          local node = api.tree.get_node_under_cursor()
          if node then
            if node.type == 'directory' then
              api.node.open.edit()
            else
              api.node.open.edit()
            end
          end
        end, { buffer = bufnr, noremap = true, silent = true, desc = 'Open with mouse click' })

        -- ダブルクリックでも開く
        vim.keymap.set('n', '<2-LeftMouse>', function()
          local node = api.tree.get_node_under_cursor()
          if node then
            api.node.open.edit()
          end
        end, { buffer = bufnr, noremap = true, silent = true, desc = 'Open with double click' })
      end,
      -- レンダラー設定
      renderer = {
        group_empty = true, -- 空ディレクトリをグループ化
        icons = {
          show = {
            file = true,
            folder = true,
            folder_arrow = true,
            git = true,
          },
        },
      },
      -- フィルター設定
      filters = {
        dotfiles = false, -- .で始まるファイルを表示
      },
      -- git統合
      git = {
        enable = true,
        ignore = false,
      },
    })
  end,
  keys = {
    { "<C-n>", "<cmd>NvimTreeToggle<CR>", desc = "Toggle NvimTree" },
  },
}

