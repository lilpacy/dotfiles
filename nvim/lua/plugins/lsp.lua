-- 共通のon_attach関数（他のプラグインからも使用可能）
local M = {}

M.on_attach = function(client, bufnr)
        -- typescript-tools以外のTypeScript LSPは定義ジャンプを無効化（重複回避）
        if client.name == "tsserver"
          or client.name == "ts_ls"
          or client.name == "typescript-language-server"
          or client.name == "vtsls"
        then
          client.server_capabilities.definitionProvider = false
          client.server_capabilities.typeDefinitionProvider = false
        end

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

        -- VSCode風のCode Action (Ctrl+. でimport文の自動追加など)
        bufmap('n', '<C-.>', vim.lsp.buf.code_action, 'Code Action')
        bufmap('v', '<C-.>', vim.lsp.buf.code_action, 'Code Action')
      end

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
          -- ts_ls は typescript-tools.nvim に移行したため削除
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
      })

      -- ts_lsの定義ジャンプ機能を無効化（typescript-toolsと競合するため）
      vim.lsp.config('ts_ls', {
        on_attach = M.on_attach,  -- カスタムon_attachを使用して、definitionProviderを無効化
        enabled = false,  -- 可能なら起動自体を無効化
      })

      -- LSPサーバーを有効化 (ts_ls は typescript-tools.nvim に移行)
      vim.lsp.enable({ 'lua_ls', 'tailwindcss', 'eslint', 'jsonls', 'clangd' })

      -- on_attachをグローバルに公開（typescript-tools.nvimで再利用するため）
      _G.lsp_on_attach = M.on_attach
    end,
  },
}
