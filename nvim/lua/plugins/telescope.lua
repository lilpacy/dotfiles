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
        local opts = {}
        local m = vim.fn.mode()
        if m == "v" or m == "V" or m == "\22" then
          local saved = vim.fn.getreg("v")
          vim.cmd('noau normal! "vy')
          local text = vim.fn.getreg("v") or ""
          vim.fn.setreg("v", saved)
          text = text:gsub("\n", " "):gsub('"', '\\"')
          opts.default_text = '"' .. text .. '"'
        end
        require("telescope").extensions.live_grep_args.live_grep_args(opts)
      end,
      mode = { "n", "x" },
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

    -- TelescopePrompt 内では bracketed paste をそのまま入力として流し込む。
    -- (Telescope の prompt buffer は通常の vim.paste 経路と相性が悪く、
    -- Cmd+V で picker が閉じてしまう症状を回避する)
    do
      local original_paste = vim.paste
      vim.paste = function(lines, phase)
        local bufnr = vim.api.nvim_get_current_buf()
        if vim.bo[bufnr].filetype == "TelescopePrompt" then
          if phase == -1 or phase == 1 then
            local text = table.concat(lines, "\n")
            text = text:gsub("\r\n", "\n"):gsub("\r", "\n"):gsub("\n", " ")
            vim.schedule(function()
              if vim.api.nvim_buf_is_valid(bufnr) then
                vim.api.nvim_feedkeys(
                  vim.api.nvim_replace_termcodes(text, true, false, true),
                  "i",
                  false
                )
              end
            end)
          end
          return true
        end
        return original_paste(lines, phase)
      end
    end

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
            -- Insert-mode Esc は close せず normal mode に戻す。
            -- bracketed paste の先頭 ESC が close を誤発火させるのを避けるため。
            ["<Esc>"] = false,
            ["<C-c>"] = actions.close,
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-u>"] = false,
          },
          n = {
            ["<Esc>"] = actions.close,
            ["q"] = actions.close,
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
          auto_quoting = false,
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
              ["<M-i>"] = lga_actions.quote_prompt({ postfix = " --ignore-case" }),    -- 大文字小文字を無視 (Aa OFF) ※<C-i>は<Tab>と衝突するため<M-i>に変更
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
