return {
  "nvim-tree/nvim-tree.lua",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },

  -- 起動時にディレクトリならNvimTreeを現在のウィンドウで開く
  init = function()
    local function open_nvim_tree(data)
      local directory = vim.fn.isdirectory(data.file) == 1
      if not directory then
        return
      end

      vim.cmd.cd(data.file)

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
        if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].filetype ~= "NvimTree" then
          return
        end

        if key == "<LeftMouse>" then
          local m = vim.fn.getmousepos()
          _G.nvim_tree_mouse_state.press = {
            winid = m.winid,
            line = m.line,
            column = m.column,
            time = vim.loop.now(),
            dragged = false,
          }
        elseif key == "<LeftDrag>" then
          if _G.nvim_tree_mouse_state.press then
            _G.nvim_tree_mouse_state.press.dragged = true
          end
        end
      end, vim.api.nvim_create_namespace("nvim-tree-mouse-watch"))
    end

    require("nvim-tree").setup({
      view = {
        width = function()
          return _G.nvim_tree_manual_width or 30
        end,
        side = "left",
        preserve_window_proportions = true,
      },
      update_focused_file = {
        enable = true,
        update_root = false,
        exclude = function(event)
          local bufnr = event.buf
          if not bufnr or bufnr <= 0 then
            return true
          end
          if not vim.api.nvim_buf_is_valid(bufnr) then
            return true
          end
          local buftype = vim.bo[bufnr].buftype
          return buftype == "nofile" or buftype == "terminal" or buftype == "quickfix" or buftype == "prompt"
        end,
      },
      hijack_unnamed_buffer_when_opening = false,
      hijack_directories = {
        enable = false,
        auto_open = false,
      },
      actions = {
        open_file = {
          quit_on_open = false,
          resize_window = true,
          window_picker = {
            enable = true,
          },
        },
      },
      on_attach = function(bufnr)
        local api = require("nvim-tree.api")

        api.config.mappings.default_on_attach(bufnr)

        local function opts(desc)
          return { buffer = bufnr, noremap = true, silent = true, desc = desc }
        end

        -- netrw風キーバインド
        vim.keymap.set("n", "t", api.node.open.tab, opts("Open in new tab"))
        vim.keymap.set("n", "v", api.node.open.vertical, opts("Open vertical split"))
        vim.keymap.set("n", "o", api.node.open.horizontal, opts("Open horizontal split"))
        vim.keymap.set("n", "-", api.tree.change_root_to_parent, opts("Go to parent dir"))
        vim.keymap.set("n", "%", api.fs.create, opts("Create file"))
        vim.keymap.set("n", "d", api.fs.create, opts("Create directory"))
        vim.keymap.set("n", "D", api.fs.remove, opts("Delete"))
        vim.keymap.set("n", "R", api.fs.rename, opts("Rename"))
        vim.keymap.set("n", "<CR>", api.node.open.edit, opts("Open"))

        -- 左ボタンを離したときに「クリックかドラッグか」を判定
        vim.keymap.set("n", "<LeftRelease>", function()
          local press = _G.nvim_tree_mouse_state.press
          _G.nvim_tree_mouse_state.press = nil

          if not press then
            return "<LeftRelease>"
          end

          if press.dragged then
            return "<LeftRelease>"
          end

          local m = vim.fn.getmousepos()

          if m.winid ~= press.winid then
            return "<LeftRelease>"
          end

          if m.line == 0 or m.column == 0 then
            return "<LeftRelease>"
          end

          local dline = math.abs(m.line - press.line)
          local dcolumn = math.abs(m.column - press.column)
          if dline + dcolumn > 1 then
            return "<LeftRelease>"
          end

          local dt = vim.loop.now() - press.time
          if dt > 500 then
            return "<LeftRelease>"
          end

          vim.schedule(function()
            api.node.open.edit()
          end)
          return ""
        end, vim.tbl_extend("force", opts("Open with single click"), { expr = true, replace_keycodes = false }))

        vim.keymap.set("n", "<C-S-h>", function()
          local node = api.tree.get_node_under_cursor()

          if not node then
            print("No node selected")
            return
          end

          local path = node.absolute_path
          vim.cmd("tab split")
          require("grug-far").open({
            prefills = { paths = path },
            transient = true,
          })
          vim.cmd("wincmd o")

          local vim_api = vim.api
          for _, hidden_bufnr in ipairs(vim_api.nvim_list_bufs()) do
            if vim_api.nvim_buf_is_valid(hidden_bufnr) and vim_api.nvim_buf_is_loaded(hidden_bufnr) then
              local name = vim_api.nvim_buf_get_name(hidden_bufnr)
              local modified = vim_api.nvim_get_option_value("modified", { buf = hidden_bufnr })
              if name == "" and not modified then
                vim_api.nvim_set_option_value("buflisted", false, { buf = hidden_bufnr })
              end
            end
          end
        end, opts("Search & Replace in this path"))
      end,
      renderer = {
        group_empty = true,
        icons = {
          show = {
            file = true,
            folder = true,
            folder_arrow = true,
            git = true,
          },
        },
      },
      filters = {
        dotfiles = false,
      },
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
    vim.api.nvim_create_autocmd("WinResized", {
      callback = function()
        local wins = vim.api.nvim_tabpage_list_wins(0)

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
