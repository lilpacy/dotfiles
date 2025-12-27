return {
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
          "ts_ls",           -- TypeScript/JavaScript
          "tailwindcss",     -- Tailwind CSS (Next.jsでよく使う)
          "eslint",          -- ESLint
          "jsonls",          -- JSON (package.json, tsconfig.jsonなど)
        },
        automatic_installation = true,
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

      -- LSPキーマッピング
      local on_attach = function(client, bufnr)
        local bufmap = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
        end

        -- LSP定義ジャンプ（ジャンプリストに確実に記録）
        local function goto_definition_with_jump()
          vim.cmd("normal! m'")  -- 現在位置をジャンプリストに保存
          vim.lsp.buf.definition({ reuse_win = true })
        end

        -- 基本のキーマップ
        bufmap('n', 'gd', goto_definition_with_jump, '定義へジャンプ')
        bufmap('n', 'gi', vim.lsp.buf.implementation, '実装へジャンプ')
        bufmap('n', 'gr', vim.lsp.buf.references, '参照を表示')
        bufmap('n', 'K', vim.lsp.buf.hover, 'ホバー情報')
        bufmap('n', '<leader>rn', vim.lsp.buf.rename, 'リネーム')
        bufmap('n', 'gt', vim.lsp.buf.type_definition, '型定義へジャンプ')

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
        if client.supports_method('textDocument/declaration') then
          bufmap('n', 'gD', vim.lsp.buf.declaration, '宣言へジャンプ')
        end

        -- Cmd+Click で定義にジャンプ (VSCode風)
        bufmap('n', '<D-LeftMouse>', function()
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<LeftMouse>', true, false, true), 'n', false)
          goto_definition_with_jump()
        end, 'Cmd+Click で定義へ')

        -- Ctrl+Click でも定義にジャンプ
        bufmap('n', '<C-LeftMouse>', function()
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<LeftMouse>', true, false, true), 'n', false)
          goto_definition_with_jump()
        end, 'Ctrl+Click で定義へ')
      end

      -- LSPサーバーの設定
      local lspconfig = require('lspconfig')

      lspconfig.lua_ls.setup({
        on_attach = on_attach,
        settings = {
          Lua = {
            diagnostics = {
              globals = { 'vim' }
            }
          }
        }
      })

      -- TypeScript/JavaScript (Next.js対応)
      lspconfig.ts_ls.setup({
        on_attach = on_attach,
        settings = {
          typescript = {
            inlayHints = {
              includeInlayParameterNameHints = 'all',
              includeInlayParameterNameHintsWhenArgumentMatchesName = false,
              includeInlayFunctionParameterTypeHints = true,
              includeInlayVariableTypeHints = true,
              includeInlayPropertyDeclarationTypeHints = true,
              includeInlayFunctionLikeReturnTypeHints = true,
              includeInlayEnumMemberValueHints = true,
            }
          },
          javascript = {
            inlayHints = {
              includeInlayParameterNameHints = 'all',
              includeInlayParameterNameHintsWhenArgumentMatchesName = false,
              includeInlayFunctionParameterTypeHints = true,
              includeInlayVariableTypeHints = true,
              includeInlayPropertyDeclarationTypeHints = true,
              includeInlayFunctionLikeReturnTypeHints = true,
              includeInlayEnumMemberValueHints = true,
            }
          }
        }
      })

      -- Tailwind CSS
      lspconfig.tailwindcss.setup({
        on_attach = on_attach,
      })

      -- ESLint
      lspconfig.eslint.setup({
        on_attach = on_attach,
      })

      -- JSON
      lspconfig.jsonls.setup({
        on_attach = on_attach,
      })
    end,
  },
}
