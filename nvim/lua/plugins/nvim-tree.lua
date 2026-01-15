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
    -- 手動で変更した幅を保存する変数（nilの場合はデフォルト幅30を使用）
    _G.nvim_tree_manual_width = nil
    -- 自動復元中かどうかのフラグ（自動復元中のWinResizedを無視するため）
    _G.nvim_tree_restoring_width = false

    require("nvim-tree").setup({
      -- ビューの設定
      view = {
        width = 30,
        side = "left",
        preserve_window_proportions = true, -- nvim-tree以外のウィンドウ比率を保持
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
          resize_window = false, -- BufWinEnterで復元するため、ここでは自動調整しない
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

    -- nvim-treeの幅を固定（:wincmd =などで自動変更されないように）
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "NvimTree",
      callback = function()
        vim.cmd("setlocal winfixwidth")
      end,
    })

    -- nvim-treeの幅が手動で変更されたときに保存
    -- 1ウィンドウのみの場合(treeが全幅になる)は手動変更とみなさない
    -- 自動復元中のWinResizedは無視する
    vim.api.nvim_create_autocmd("WinResized", {
      callback = function()
        -- 自動復元中は無視
        if _G.nvim_tree_restoring_width then
          return
        end

        -- 1つしかウィンドウがないときは無視
        local wins = vim.api.nvim_tabpage_list_wins(0)
        if #wins <= 1 then
          return
        end

        local winid = vim.api.nvim_get_current_win()
        local bufnr = vim.api.nvim_win_get_buf(winid)
        local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })

        if ft == "NvimTree" then
          local width = vim.api.nvim_win_get_width(winid)
          _G.nvim_tree_manual_width = width
        end
      end,
    })

    -- nvim-treeを開くときに保存された幅を復元
    vim.api.nvim_create_autocmd("BufWinEnter", {
      pattern = "NvimTree_*",
      callback = function()
        -- 自動復元中フラグを立てる
        _G.nvim_tree_restoring_width = true

        local winid = vim.api.nvim_get_current_win()
        local width = _G.nvim_tree_manual_width or 30
        vim.api.nvim_win_set_width(winid, width)

        -- 復元後、少し待ってからフラグを下ろす
        vim.schedule(function()
          _G.nvim_tree_restoring_width = false
        end)
      end,
    })

    -- 手動で変更した幅をリセットしてデフォルト(30)に戻すコマンド
    vim.api.nvim_create_user_command("NvimTreeResetWidth", function()
      _G.nvim_tree_manual_width = nil
      -- 開いているnvim-treeがあれば即座に30に戻す
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local bufnr = vim.api.nvim_win_get_buf(win)
        local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
        if ft == "NvimTree" then
          vim.api.nvim_win_set_width(win, 30)
        end
      end
      print("NvimTree width reset to default (30)")
    end, {})
  end,
  keys = {
    { "<C-n>", "<cmd>NvimTreeToggle<CR>", desc = "Toggle NvimTree" },
  },
}
