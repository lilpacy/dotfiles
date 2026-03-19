return {
  "nvim-telescope/telescope.nvim",
  branch = "0.1.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    { "nvim-telescope/telescope-live-grep-args.nvim", version = "^1.0.0" },
  },
  keys = {
    -- VSCode style keybindings (Ctrl instead of Cmd for terminal)
    { "<C-p>", "<cmd>Telescope find_files<cr>", desc = "Quick Open (Cmd+P)" },
    { "<C-S-p>", "<cmd>Telescope commands<cr>", desc = "Command Palette (Cmd+Shift+P)" },
    {
      "<C-S-f>",
      function()
        require("telescope").extensions.live_grep_args.live_grep_args()
      end,
      desc = "Search in Files (Cmd+Shift+F)",
    },
    { "<C-S-e>", "<cmd>Telescope buffers<cr>", desc = "Explorer/Buffers (Cmd+Shift+E)" },
    { "<C-S-o>", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Go to Symbol (Cmd+Shift+O)" },
    { "<C-t>", "<cmd>Telescope lsp_workspace_symbols<cr>", desc = "Go to Symbol in Workspace (Cmd+T)" },
    -- Additional useful mappings
    { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
    {
      "<leader>fg",
      function()
        require("telescope").extensions.live_grep_args.live_grep_args()
      end,
      desc = "Live grep",
    },
    { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent files" },
    { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
  },
  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")
    local lga_actions = require("telescope-live-grep-args.actions")

    telescope.setup({
      defaults = {
        vimgrep_arguments = {
          "rg",
          "--color=never",
          "--no-heading",
          "--with-filename",
          "--line-number",
          "--column",
          "--smart-case",
          "--hidden",  -- 隠しファイル（dotfiles）も検索対象に含める
          "--glob", "!.git/*",  -- .gitディレクトリは除外
        },
        file_ignore_patterns = { "node_modules", ".git/" },
        mappings = {
          i = {
            ["<Esc>"] = actions.close,  -- VSCode: Esc closes immediately
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-u>"] = false,  -- Clear line like VSCode
            ["<D-v>"] = function()
              vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-r>+', true, true, true), 'n', false)
            end,
          },
        },
      },
      pickers = {
        find_files = {
          hidden = true,
        },
      },
      extensions = {
        live_grep_args = {
          auto_quoting = true,
          mappings = {
            i = {
              -- 検索結果を開いた時に該当行にジャンプする（autocmdとの競合回避）
              ["<CR>"] = function(prompt_bufnr)
                local action_state = require("telescope.actions.state")
                local entry = action_state.get_selected_entry()
                actions.select_default(prompt_bufnr)
                if entry and entry.lnum then
                  vim.schedule(function()
                    pcall(vim.api.nvim_win_set_cursor, 0, { entry.lnum, (entry.col or 1) - 1 })
                  end)
                end
              end,
              -- VSCode風の検索オプション切り替え（複数組み合わせ可能）
              ["<C-k>"] = lga_actions.quote_prompt(),                            -- クォートで囲む
              ["<C-s>"] = lga_actions.quote_prompt({ postfix = " --case-sensitive" }), -- 大文字小文字を区別 (Aa ON)
              ["<C-i>"] = lga_actions.quote_prompt({ postfix = " --ignore-case" }),    -- 大文字小文字を無視 (Aa OFF)
              ["<C-w>"] = lga_actions.quote_prompt({ postfix = " -w" }),               -- 単語完全一致 (Ab| ON)
              ["<C-f>"] = lga_actions.quote_prompt({ postfix = " -F" }),               -- リテラル検索 (.* OFF)
            },
          },
        },
      },
    })

    telescope.load_extension("fzf")
    telescope.load_extension("live_grep_args")
  end,
}
