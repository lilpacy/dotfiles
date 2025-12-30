return {
  "nvim-telescope/telescope.nvim",
  tag = "v0.2.0",
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
    local action_state = require("telescope.actions.state")

    -- フラグを追加するカスタム関数（既存フラグを保持）
    local function append_flag(flag)
      return function(prompt_bufnr)
        local picker = action_state.get_current_picker(prompt_bufnr)
        local prompt = picker:_get_prompt()

        -- 既にそのフラグがあれば何もしない
        if prompt:find(flag, 1, true) then
          return
        end

        -- クォートされていなければクォートする
        if not prompt:match('^"') then
          prompt = '"' .. prompt .. '"'
        end

        -- フラグを末尾に追加
        prompt = prompt .. " " .. flag

        -- プロンプトを更新
        picker:set_prompt(prompt)
      end
    end

    telescope.setup({
      defaults = {
        file_ignore_patterns = { "node_modules", ".git/" },
        mappings = {
          i = {
            ["<Esc>"] = actions.close,  -- VSCode: Esc closes immediately
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-u>"] = false,  -- Clear line like VSCode
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
              -- VSCode風の検索オプション切り替え（複数組み合わせ可能）
              ["<C-k>"] = lga_actions.quote_prompt(),              -- クォートで囲む
              ["<C-s>"] = append_flag("--case-sensitive"),         -- 大文字小文字を区別 (Aa ON)
              ["<C-i>"] = append_flag("--ignore-case"),            -- 大文字小文字を無視 (Aa OFF)
              ["<C-w>"] = append_flag("-w"),                       -- 単語完全一致 (Ab| ON)
              ["<C-f>"] = append_flag("-F"),                       -- リテラル検索 (.* OFF)
            },
          },
        },
      },
    })

    telescope.load_extension("fzf")
    telescope.load_extension("live_grep_args")
  end,
}
