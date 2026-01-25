-- 共通のon_attach関数（他のプラグインからも使用可能）
local M = {}

M.on_attach = function(client, bufnr)
        -- typescript-tools以外のTypeScript LSPは定義ジャンプ・参照を無効化（重複回避）
        if client.name == "tsserver"
          or client.name == "ts_ls"
          or client.name == "typescript-language-server"
          or client.name == "vtsls"
        then
          client.server_capabilities.definitionProvider = false
          client.server_capabilities.typeDefinitionProvider = false
          client.server_capabilities.referencesProvider = false
        end

        local bufmap = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
        end

        -- カスタム定義ジャンプ（Telescope UIで複数候補を表示）
        local function goto_definition_telescope()
          vim.cmd("normal! m'")  -- 現在位置をジャンプリストに保存
          vim.lsp.buf.definition({
            on_list = function(options)
              local items = options.items or {}
              if #items == 0 then
                vim.notify('定義が見つかりませんでした', vim.log.levels.INFO)
                return
              elseif #items == 1 then
                -- 候補が1つなら直接ジャンプ
                local item = items[1]
                vim.cmd.edit(item.filename)
                vim.api.nvim_win_set_cursor(0, {item.lnum, item.col - 1})
              else
                -- 複数候補はTelescopeで表示（quickfixを経由せず直接pickerを作成）
                local pickers = require('telescope.pickers')
                local finders = require('telescope.finders')
                local conf = require('telescope.config').values
                local actions = require('telescope.actions')
                local action_state = require('telescope.actions.state')

                vim.schedule(function()
                  pickers.new({}, {
                    prompt_title = options.title or 'LSP Definitions',
                    finder = finders.new_table({
                      results = items,
                      entry_maker = function(item)
                        local filename = item.filename or vim.api.nvim_buf_get_name(item.bufnr or 0)
                        local display_filename = vim.fn.fnamemodify(filename, ':.')
                        return {
                          value = item,
                          path = filename,
                          lnum = item.lnum,
                          col = item.col,
                          ordinal = display_filename .. ' ' .. (item.text or ''),
                          display = string.format('%s:%d:%d: %s',
                            display_filename, item.lnum or 0, item.col or 0, item.text or ''),
                        }
                      end,
                    }),
                    sorter = conf.generic_sorter({}),
                    previewer = conf.grep_previewer({}),
                    attach_mappings = function(prompt_bufnr)
                      actions.select_default:replace(function()
                        actions.close(prompt_bufnr)
                        local selection = action_state.get_selected_entry()
                        if not selection or not selection.value then return end
                        local loc = selection.value
                        local filename = loc.filename or (loc.bufnr and vim.api.nvim_buf_get_name(loc.bufnr))
                        if not filename or filename == '' then return end
                        vim.cmd.edit(filename)
                        vim.api.nvim_win_set_cursor(0, { loc.lnum, (loc.col or 1) - 1 })
                      end)
                      return true
                    end,
                  }):find()
                end)
              end
            end,
          })
        end

        -- 基本のキーマップ
        bufmap('n', 'gd', goto_definition_telescope, '定義へジャンプ')
        bufmap('n', 'gi', function() require('telescope.builtin').lsp_implementations() end, '実装へジャンプ')
        bufmap('n', 'gr', function() require('telescope.builtin').lsp_references() end, '参照を表示')
        bufmap('n', 'K', vim.lsp.buf.hover, 'ホバー情報')
        bufmap('n', '<leader>rn', vim.lsp.buf.rename, 'リネーム')
        bufmap('n', 'gt', function() require('telescope.builtin').lsp_type_definitions() end, '型定義へジャンプ')

        -- VSCode風の戻る/進む（確実に動作するキー）
        bufmap('n', 'gb', function()
          local key = vim.api.nvim_replace_termcodes('<C-o>', true, false, true)
          vim.api.nvim_feedkeys(key, 'n', false)
        end, 'Go Back: 前の場所へ戻る')
        bufmap('n', 'gF', function()
          local key = vim.api.nvim_replace_termcodes('<C-i>', true, false, true)
          vim.api.nvim_feedkeys(key, 'n', false)
        end, 'Go Forward: 次の場所へ進む')

        -- declarationはサーバーが対応している場合のみ
        if client:supports_method('textDocument/declaration') then
          bufmap('n', 'gD', vim.lsp.buf.declaration, '宣言へジャンプ')
        end

        -- Cmd+Click で定義にジャンプ (VSCode風)
        bufmap('n', '<D-LeftMouse>', function()
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<LeftMouse>', true, false, true), 'n', false)
          goto_definition_telescope()
        end, 'Cmd+Click で定義へ')

        -- Ctrl+Click でも定義にジャンプ
        bufmap('n', '<C-LeftMouse>', function()
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<LeftMouse>', true, false, true), 'n', false)
          goto_definition_telescope()
        end, 'Ctrl+Click で定義へ')

        -- VSCode風のCode Action (Ctrl+. でimport文の自動追加など)
        bufmap('n', '<C-.>', vim.lsp.buf.code_action, 'Code Action')
        bufmap('v', '<C-.>', vim.lsp.buf.code_action, 'Code Action')

        -- 診断（Diagnostics）
        bufmap('n', 'gl', vim.diagnostic.open_float, '診断をフロートで表示')
        bufmap('n', '[d', vim.diagnostic.goto_prev, '前の診断へ')
        bufmap('n', ']d', vim.diagnostic.goto_next, '次の診断へ')
      end

return {
  -- LSP進捗表示
  {
    "j-hui/fidget.nvim",
    opts = {},
  },

  -- LSP設定
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
    },
    config = function()
      -- Masonのセットアップ
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",
          "tailwindcss",     -- Tailwind CSS (Next.jsでよく使う)
          "eslint",          -- ESLint
          "jsonls",          -- JSON (package.json, tsconfig.jsonなど)
        },
        -- mason-lspconfig v2: 自動有効化を無効にし、vim.lsp.enable()で明示的に管理
        automatic_enable = false,
      })

      -- フォーマッタの自動インストール
      require("mason-tool-installer").setup({
        ensure_installed = {
          "prettierd",       -- Prettier daemon (高速版)
          "prettier",        -- Prettier (フォールバック用)
          "stylua",          -- Lua formatter
        },
        auto_update = false,
        run_on_start = true,
      })

      -- LSPサーバーの設定 (Neovim 0.11+ の新しいAPI)
      vim.lsp.config('lua_ls', {
        on_attach = M.on_attach,
        settings = {
          Lua = {
            diagnostics = {
              globals = { 'vim' }
            }
          }
        }
      })

      -- TypeScript/JavaScript は typescript-tools.nvim で管理

      -- Tailwind CSS
      vim.lsp.config('tailwindcss', {
        on_attach = M.on_attach,
      })

      -- ESLint
      vim.lsp.config('eslint', {
        on_attach = M.on_attach,
      })

      -- JSON
      vim.lsp.config('jsonls', {
        on_attach = M.on_attach,
      })

      -- C/C++ (clangd)
      vim.lsp.config('clangd', {
        on_attach = M.on_attach,
        cmd = { 'clangd', '--background-index' },
      })

      -- LSPサーバーを有効化 (ts_ls は typescript-tools.nvim に移行)
      vim.lsp.enable({ 'lua_ls', 'tailwindcss', 'eslint', 'jsonls', 'clangd' })

      -- on_attachをグローバルに公開（typescript-tools.nvimで再利用するため）
      _G.lsp_on_attach = M.on_attach
    end,
  },
}
