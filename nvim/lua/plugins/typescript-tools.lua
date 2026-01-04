return {
  "pmizio/typescript-tools.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "neovim/nvim-lspconfig",
  },
  ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
  config = function()
    local on_attach = function(client, bufnr)
      local bufmap = function(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
      end

      -- LSP定義ジャンプ（ジャンプリストに確実に記録）
      local function goto_definition_with_jump()
        vim.cmd("normal! m'")
        vim.lsp.buf.definition({ reuse_win = true })
      end

      -- 基本のキーマップ
      bufmap('n', 'gd', goto_definition_with_jump, '定義へジャンプ')
      bufmap('n', 'gi', vim.lsp.buf.implementation, '実装へジャンプ')
      bufmap('n', 'gr', vim.lsp.buf.references, '参照を表示')
      bufmap('n', 'K', vim.lsp.buf.hover, 'ホバー情報')
      bufmap('n', '<leader>rn', vim.lsp.buf.rename, 'リネーム')
      bufmap('n', 'gt', vim.lsp.buf.type_definition, '型定義へジャンプ')

      -- Go to Source Definition (ライブラリ実装へジャンプ)
      bufmap('n', 'gs', '<cmd>TSToolsGoToSourceDefinition<CR>', 'ソース実装へジャンプ')

      -- VSCode風の戻る/進む
      bufmap('n', 'gb', function()
        local key = vim.api.nvim_replace_termcodes('<C-o>', true, false, true)
        vim.api.nvim_feedkeys(key, 'n', false)
      end, 'Go Back: 前の場所へ戻る')
      bufmap('n', 'gF', function()
        local key = vim.api.nvim_replace_termcodes('<C-i>', true, false, true)
        vim.api.nvim_feedkeys(key, 'n', false)
      end, 'Go Forward: 次の場所へ進む')

      -- Cmd+Click / Ctrl+Click で定義にジャンプ
      bufmap('n', '<D-LeftMouse>', function()
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<LeftMouse>', true, false, true), 'n', false)
        goto_definition_with_jump()
      end, 'Cmd+Click で定義へ')

      bufmap('n', '<C-LeftMouse>', function()
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<LeftMouse>', true, false, true), 'n', false)
        goto_definition_with_jump()
      end, 'Ctrl+Click で定義へ')

      -- VSCode風のCode Action
      bufmap('n', '<C-.>', vim.lsp.buf.code_action, 'Code Action')
      bufmap('v', '<C-.>', vim.lsp.buf.code_action, 'Code Action')
    end

    require("typescript-tools").setup({
      on_attach = on_attach,
      settings = {
        tsserver_file_preferences = {
          includeInlayParameterNameHints = "all",
          includeInlayParameterNameHintsWhenArgumentMatchesName = false,
          includeInlayFunctionParameterTypeHints = true,
          includeInlayVariableTypeHints = true,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayFunctionLikeReturnTypeHints = true,
          includeInlayEnumMemberValueHints = true,
        },
      },
    })
  end,
}
