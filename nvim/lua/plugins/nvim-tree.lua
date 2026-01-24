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
    -- 手動で変更した幅を保存する変数（デフォルトは30）
    _G.nvim_tree_manual_width = 30

    -- マウス状態の初期化
    if not _G.nvim_tree_mouse_state then
      _G.nvim_tree_mouse_state = { press = nil }
    end

    -- vim.on_key で<LeftMouse>と<LeftDrag>を監視（マッピングはしない）
    if not _G.nvim_tree_mouse_listener_registered then
      _G.nvim_tree_mouse_listener_registered = true
      vim.on_key(function(char)
        local key = vim.fn.keytrans(char)

        -- nvim-tree バッファ以外では無視
        local buf = vim.api.nvim_get_current_buf()
        if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].filetype ~= 'NvimTree' then
          return
        end

        if key == '<LeftMouse>' then
          local m = vim.fn.getmousepos()
          _G.nvim_tree_mouse_state.press = {
            winid = m.winid,
            line = m.line,
            column = m.column,
            time = vim.loop.now(),
            dragged = false,
          }
        elseif key == '<LeftDrag>' then
          if _G.nvim_tree_mouse_state.press then
            _G.nvim_tree_mouse_state.press.dragged = true
          end
        end
      end, vim.api.nvim_create_namespace('nvim-tree-mouse-watch'))
    end

    require("nvim-tree").setup({
      -- ビューの設定
      view = {
        -- 幅はグローバル変数から読む関数にする
        width = function()
          return _G.nvim_tree_manual_width or 30
        end,
        side = "left",
        preserve_window_proportions = true, -- nvim-tree以外のウィンドウ比率を保持
      },
      -- バッファ切り替え時に自動的にnvim-treeのフォーカスを追従
      update_focused_file = {
        enable = true,
        update_root = false, -- ルートディレクトリは変更しない
        exclude = function(event)
          -- event は BufEnter イベントオブジェクト、バッファ番号は event.buf
          local bufnr = event.buf
          if not bufnr or bufnr <= 0 then
            return true
          end
          if not vim.api.nvim_buf_is_valid(bufnr) then
            return true
          end
          local buftype = vim.bo[bufnr].buftype
          -- terminal、nofile、quickfix、promptなどのバッファはスキップ
          return buftype == "nofile" or buftype == "terminal" or buftype == "quickfix" or buftype == "prompt"
        end,
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
          resize_window = true, -- ファイルを開くときにview.width()の値にリサイズ
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

        -- 左ボタンを離したときに「クリックかドラッグか」を判定（exprマッピング）
        vim.keymap.set('n', '<LeftRelease>', function()
          local press = _G.nvim_tree_mouse_state.press
          _G.nvim_tree_mouse_state.press = nil

          -- このバッファ上での押下イベントがなければデフォルト動作
          if not press then
            return '<LeftRelease>'
          end

          -- ドラッグが発生していたらデフォルト動作（リサイズなど）
          if press.dragged then
            return '<LeftRelease>'
          end

          local m = vim.fn.getmousepos()

          -- 押下時と別ウィンドウで離された場合はデフォルト動作
          if m.winid ~= press.winid then
            return '<LeftRelease>'
          end

          -- 分割線やステータスラインで離した場合はデフォルト動作
          if m.line == 0 or m.column == 0 then
            return '<LeftRelease>'
          end

          -- 移動量が大きければドラッグとみなしてデフォルト動作
          local dline = math.abs(m.line - press.line)
          local dcolumn = math.abs(m.column - press.column)
          if dline + dcolumn > 1 then
            return '<LeftRelease>'
          end

          -- 押下から離すまでの時間が長いものをドラッグ扱い
          local dt = vim.loop.now() - press.time
          if dt > 500 then
            return '<LeftRelease>'
          end

          -- ここまで来たら「ほぼその場でのクリック」とみなし、ノードを開く
          -- exprマッピング内ではバッファ変更ができないのでvim.schedule()で非同期実行
          vim.schedule(function()
            api.node.open.edit()
          end)
          return '' -- 処理済みなので<LeftRelease>をVimに渡さない
        end, vim.tbl_extend('force', opts('Open with single click'), { expr = true, replace_keycodes = false }))

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
    vim.api.nvim_create_autocmd("WinResized", {
      callback = function()
        local wins = vim.api.nvim_tabpage_list_wins(0)

        -- NvimTreeだけの全画面状態は「手動幅」とみなさない
        if #wins <= 1 then
          return
        end

        for _, winid in ipairs(wins) do
          local bufnr = vim.api.nvim_win_get_buf(winid)
          local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
          if ft == "NvimTree" then
            _G.nvim_tree_manual_width = vim.api.nvim_win_get_width(winid)
            break
          end
        end
      end,
    })

    -- 手動で変更した幅をリセットしてデフォルト(30)に戻すコマンド
    vim.api.nvim_create_user_command("NvimTreeResetWidth", function()
      _G.nvim_tree_manual_width = 30
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
