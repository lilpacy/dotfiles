return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
  },

  -- 起動時にディレクトリならneo-treeを現在のウィンドウで開く
  init = function()
    local function open_neo_tree(data)
      local directory = vim.fn.isdirectory(data.file) == 1
      if not directory then
        return
      end

      vim.cmd.cd(data.file)

      require("neo-tree.command").execute({
        action = "focus",
        source = "filesystem",
        position = "current",
      })
    end

    vim.api.nvim_create_autocmd("VimEnter", {
      callback = open_neo_tree,
    })
  end,

  config = function()
    -- 手動で変更した幅を保存する変数（デフォルトは30）
    _G.neo_tree_manual_width = 30

    -- マウス状態の初期化
    if not _G.neo_tree_mouse_state then
      _G.neo_tree_mouse_state = { press = nil }
    end

    -- vim.on_key で<LeftMouse>と<LeftDrag>を監視（マッピングはしない）
    if not _G.neo_tree_mouse_listener_registered then
      _G.neo_tree_mouse_listener_registered = true
      vim.on_key(function(char)
        local key = vim.fn.keytrans(char)

        -- neo-tree バッファ以外では無視
        local buf = vim.api.nvim_get_current_buf()
        if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].filetype ~= 'neo-tree' then
          return
        end

        if key == '<LeftMouse>' then
          local m = vim.fn.getmousepos()
          _G.neo_tree_mouse_state.press = {
            winid = m.winid,
            line = m.line,
            column = m.column,
            time = vim.loop.now(),
            dragged = false,
          }
        elseif key == '<LeftDrag>' then
          if _G.neo_tree_mouse_state.press then
            _G.neo_tree_mouse_state.press.dragged = true
          end
        end
      end, vim.api.nvim_create_namespace('neo-tree-mouse-watch'))
    end

    -- カスタムコマンド: grug-farで検索・置換
    local function search_in_path(state)
      local node = state.tree:get_node()
      if not node then
        print('No node selected')
        return
      end

      local path = node:get_id()
      vim.cmd("tab split")
      require("grug-far").open({
        prefills = { paths = path },
        transient = true,
      })
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
    end

    require("neo-tree").setup({
      close_if_last_window = true,
      popup_border_style = "rounded",
      enable_git_status = true,
      enable_diagnostics = true,
      sort_case_insensitive = true,

      -- インスタンス間でクリップボード共有（別nvim間でフォルダコピペ可能）
      clipboard = {
        sync = "universal",
      },

      -- ソースごとのセットアップ
      source_selector = {
        winbar = false,
        statusline = false,
      },

      default_component_configs = {
        indent = {
          indent_size = 2,
          padding = 1,
          with_expanders = false,
          -- インデントマーカーで階層を明確化
          with_markers = true,
          indent_marker = "│",
          last_indent_marker = "└",
          highlight = "NeoTreeIndentMarker",
        },
        modified = {
          symbol = "●",
          highlight = "NeoTreeModified",
        },
        -- ファイル名をGitステータスに応じて色付け
        name = {
          use_git_status_colors = true,
          highlight_opened_files = "foreground", -- 開いているファイルを強調
        },
        git_status = {
          symbols = {
            -- nvim-treeのデフォルトと同じシンボル
            added = "✓",
            modified = "✗",
            deleted = "",
            renamed = "➜",
            untracked = "✦",
            ignored = "◌",
            unstaged = "✗",
            staged = "✓",
            conflict = "",
          },
        },
      },

      -- Gitステータスのハイライト色
      renderers = {
        directory = {
          { "indent" },
          { "icon" },
          { "current_filter" },
          {
            "container",
            content = {
              { "name", zindex = 10 },
              { "git_status", zindex = 30, align = "right", hide_when_expanded = true },
            },
          },
        },
        file = {
          { "indent" },
          { "icon" },
          {
            "container",
            content = {
              { "name", zindex = 10 },
              { "modified", zindex = 20 },
              { "git_status", zindex = 30, align = "right" },
            },
          },
        },
      },

      -- ウィンドウ設定
      window = {
        position = "left",
        width = function()
          return _G.neo_tree_manual_width or 30
        end,
        mapping_options = {
          noremap = true,
          nowait = true,
        },
        mappings = {
          -- 基本操作
          ["<CR>"] = "open",
          ["l"] = "open",           -- NERDTree風: lで開く
          ["h"] = "close_node",     -- NERDTree風: hで閉じる
          ["<space>"] = "none",     -- space誤爆防止
          ["<esc>"] = "cancel",
          ["q"] = "close_window",
          ["R"] = "refresh",
          ["?"] = "show_help",
          ["P"] = "toggle_preview",

          -- ファイルを開く
          ["t"] = "open_tabnew",
          ["v"] = "open_vsplit",
          ["o"] = "open_split",
          ["s"] = "open_split",

          -- ナビゲーション
          ["-"] = "navigate_up",
          ["z"] = "close_all_nodes",
          ["Z"] = "expand_all_nodes",

          -- ファイル操作
          ["a"] = { "add", config = { show_path = "relative" } },
          ["%"] = { "add", config = { show_path = "relative" } },
          ["A"] = "add_directory",
          ["d"] = "add_directory",
          ["D"] = "delete",
          ["r"] = "rename",

          -- クリップボード
          ["y"] = "copy_to_clipboard",
          ["x"] = "cut_to_clipboard",
          ["p"] = "paste_from_clipboard",
          ["c"] = "copy",
          ["m"] = "move",

          -- Git操作
          ["gs"] = "git_status",
          ["gu"] = "git_unstage_file",
          ["ga"] = "git_add_file",
          ["gc"] = "git_commit",
          ["gp"] = "git_push",

          -- カスタム
          ["<C-S-h>"] = search_in_path,
        },
      },

      -- ファイルシステムソース
      filesystem = {
        filtered_items = {
          visible = false,
          hide_dotfiles = false,
          hide_gitignored = true,  -- gitignoreされたファイルを非表示
          hide_by_name = {
            "node_modules",
            ".git",
          },
        },
        follow_current_file = {
          enabled = true,
          leave_dirs_open = true,
        },
        group_empty_dirs = true,
        hijack_netrw_behavior = "disabled",
        use_libuv_file_watcher = true,
        window = {
          mappings = {
            ["H"] = "toggle_hidden",
            ["/"] = "fuzzy_finder",
            ["f"] = "filter_on_submit",
            ["<C-x>"] = "clear_filter",
            ["[g"] = "prev_git_modified",
            ["]g"] = "next_git_modified",
          },
        },
      },

      -- バッファソース
      buffers = {
        follow_current_file = {
          enabled = true,
        },
        group_empty_dirs = true,
        show_unloaded = true,
      },

      -- git_statusソース
      git_status = {
        window = {
          position = "right",
          width = 34,
        },
      },

      event_handlers = {
        {
          event = "neo_tree_buffer_enter",
          handler = function()
            vim.wo.signcolumn = "no"
          end,
        },
      },
    })

    -- neo-treeの幅を固定
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "neo-tree",
      callback = function()
        vim.cmd("setlocal winfixwidth")

        -- グローバルの/マッピングを解除してneo-treeのfilter_on_submitを有効にする
        pcall(function() vim.keymap.del('n', '/', { buffer = 0 }) end)

        -- シングルクリックでファイルを開く（exprマッピング）
        local buf = vim.api.nvim_get_current_buf()
        vim.keymap.set('n', '<LeftRelease>', function()
          local press = _G.neo_tree_mouse_state.press
          _G.neo_tree_mouse_state.press = nil

          if not press then
            return '<LeftRelease>'
          end

          if press.dragged then
            return '<LeftRelease>'
          end

          local m = vim.fn.getmousepos()

          if m.winid ~= press.winid then
            return '<LeftRelease>'
          end

          if m.line == 0 or m.column == 0 then
            return '<LeftRelease>'
          end

          local dline = math.abs(m.line - press.line)
          local dcolumn = math.abs(m.column - press.column)
          if dline + dcolumn > 1 then
            return '<LeftRelease>'
          end

          local dt = vim.loop.now() - press.time
          if dt > 500 then
            return '<LeftRelease>'
          end

          -- クリックとみなしノードを開く
          vim.schedule(function()
            local manager = require("neo-tree.sources.manager")
            local state = manager.get_state("filesystem")
            if state then
              local node = state.tree:get_node()
              if node then
                if node.type == "directory" then
                  require("neo-tree.sources.filesystem.commands").toggle_node(state)
                else
                  require("neo-tree.sources.common.commands").open(state)
                end
              end
            end
          end)
          return ''
        end, { buffer = buf, expr = true, replace_keycodes = false, desc = 'Open with single click' })
      end,
    })

    -- neo-treeの幅が手動で変更されたときに保存
    vim.api.nvim_create_autocmd("WinResized", {
      callback = function()
        local wins = vim.api.nvim_tabpage_list_wins(0)

        if #wins <= 1 then
          return
        end

        for _, winid in ipairs(wins) do
          local bufnr = vim.api.nvim_win_get_buf(winid)
          local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
          if ft == "neo-tree" then
            _G.neo_tree_manual_width = vim.api.nvim_win_get_width(winid)
            break
          end
        end
      end,
    })

    -- git操作後にneo-treeのgitステータスを自動更新
    vim.api.nvim_create_autocmd({ "FocusGained", "BufWritePost", "TermLeave" }, {
      callback = function()
        local ok, events = pcall(require, "neo-tree.events")
        if ok then
          events.fire_event("git_event")
        end
      end,
    })

    -- 手動で変更した幅をリセットしてデフォルト(30)に戻すコマンド
    vim.api.nvim_create_user_command("NeoTreeResetWidth", function()
      _G.neo_tree_manual_width = 30
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local bufnr = vim.api.nvim_win_get_buf(win)
        local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
        if ft == "neo-tree" then
          vim.api.nvim_win_set_width(win, 30)
        end
      end
      print("Neo-tree width reset to default (30)")
    end, {})
  end,

  keys = {
    { "<C-n>", "<cmd>Neotree toggle<CR>", desc = "Toggle Neo-tree" },
  },
}
