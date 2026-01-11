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
        preserve_window_proportions = true, -- 幅を変更したら保持する
      },
      -- 空の[No Name]バッファから開いたときはそのウィンドウを乗っ取る
      hijack_unnamed_buffer_when_opening = false,
      -- ディレクトリ自動オープンは自前のautocmdに任せる
      hijack_directories = {
        enable = false,
        auto_open = false,
      },
      -- ファイルを開いた時の挙動
      actions = {
        open_file = {
          quit_on_open = false,
          resize_window = false, -- 手動で変更した幅を保持する
          window_picker = {
            enable = true,
          },
        },
      },
      -- netrw風キーマッピング
      on_attach = function(bufnr)
        local api = require('nvim-tree.api')

        -- デフォルトのキーマッピングを適用
        api.config.mappings.default_on_attach(bufnr)

        local function opts(desc)
          return { buffer = bufnr, noremap = true, silent = true, desc = desc }
        end

        -- netrw風キーバインド
        vim.keymap.set('n', 't', api.node.open.tab, opts('Open in new tab'))           -- タブで開く
        vim.keymap.set('n', 'v', api.node.open.vertical, opts('Open vertical split'))  -- 垂直分割
        vim.keymap.set('n', 'o', api.node.open.horizontal, opts('Open horizontal split'))  -- 水平分割
        vim.keymap.set('n', '-', api.tree.change_root_to_parent, opts('Go to parent dir'))  -- 親ディレクトリ
        vim.keymap.set('n', '%', api.fs.create, opts('Create file'))                   -- ファイル作成
        vim.keymap.set('n', 'd', api.fs.create, opts('Create directory'))              -- ディレクトリ作成（末尾に/をつける）
        vim.keymap.set('n', 'D', api.fs.remove, opts('Delete'))                        -- 削除
        vim.keymap.set('n', 'R', api.fs.rename, opts('Rename'))                        -- リネーム
        vim.keymap.set('n', '<CR>', api.node.open.edit, opts('Open'))                  -- Enter で開く

        -- シングルクリックで開く
        vim.keymap.set('n', '<LeftRelease>', api.node.open.edit, opts('Open with single click'))

        -- Ctrl+Shift+H: カーソル下のパスでgrug-farを開く
        vim.keymap.set('n', '<C-S-h>', function()
          local node = api.tree.get_node_under_cursor()

          if not node then
            print('No node selected')
            return
          end

          local path = node.absolute_path
          vim.cmd("tab split")
          require("grug-far").open({
            prefills = { paths = path },
            transient = true,
          })
          vim.cmd("wincmd o")

          -- 名前なしの未変更バッファをbufferlineから隠す
          local vim_api = vim.api
          for _, bufnr in ipairs(vim_api.nvim_list_bufs()) do
            if vim_api.nvim_buf_is_valid(bufnr) and vim_api.nvim_buf_is_loaded(bufnr) then
              local name = vim_api.nvim_buf_get_name(bufnr)
              local modified = vim_api.nvim_get_option_value("modified", { buf = bufnr })
              if name == "" and not modified then
                vim_api.nvim_set_option_value("buflisted", false, { buf = bufnr })
              end
            end
          end
        end, opts('Search & Replace in this path'))
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
