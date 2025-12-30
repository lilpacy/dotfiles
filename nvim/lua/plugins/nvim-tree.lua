return {
  "nvim-tree/nvim-tree.lua",
  dependencies = {
    "nvim-tree/nvim-web-devicons", -- アイコン表示用
  },

  -- 起動時にディレクトリならNvimTreeを現在のウィンドウで開く
  init = function()
    local function open_nvim_tree(data)
      -- 起動時のバッファがディレクトリかどうか
      local directory = vim.fn.isdirectory(data.file) == 1
      if not directory then
        return
      end

      -- Neovimのcwdをそのディレクトリに変更
      vim.cmd.cd(data.file)

      -- このウィンドウをそのままNvimTreeに置き換える
      require("nvim-tree.api").tree.open({
        current_window = true,
      })
    end

    vim.api.nvim_create_autocmd("VimEnter", {
      callback = open_nvim_tree,
    })
  end,

  config = function()
    require("nvim-tree").setup({
      -- ビューの設定
      view = {
        width = 30,
        side = "left",
      },
      -- 空の[No Name]バッファから開いたときはそのウィンドウを乗っ取る
      hijack_unnamed_buffer_when_opening = true,
      -- ディレクトリ自動オープンは自前のautocmdに任せる
      hijack_directories = {
        enable = false,
        auto_open = false,
      },
      -- ファイルを開いた時の挙動
      actions = {
        open_file = {
          quit_on_open = false,
          window_picker = {
            enable = true,
          },
        },
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
