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

        -- デフォルトのキーマッピングを適用（<2-LeftMouse>も含む）
        api.config.mappings.default_on_attach(bufnr)

        -- シングルクリックで開く（ボタンを離したタイミング）
        vim.keymap.set('n', '<LeftRelease>', function()
          api.node.open.edit()
        end, { buffer = bufnr, noremap = true, silent = true, desc = 'Open with single click' })
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

