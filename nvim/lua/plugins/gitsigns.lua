return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    require("gitsigns").setup({
      signs = {
        add          = { text = "│" },
        change       = { text = "│" },
        delete       = { text = "_" },
        topdelete    = { text = "‾" },
        changedelete = { text = "~" },
      },
      current_line_blame = false,  -- 必要なら true に
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- ナビゲーション
        map('n', ']c', function()
          if vim.wo.diff then return ']c' end
          vim.schedule(function() gs.next_hunk() end)
          return '<Ignore>'
        end, { expr = true, desc = "次のhunkへ" })

        map('n', '[c', function()
          if vim.wo.diff then return '[c' end
          vim.schedule(function() gs.prev_hunk() end)
          return '<Ignore>'
        end, { expr = true, desc = "前のhunkへ" })

        -- 差分プレビュー（Floating window）- VSCode風の機能
        map('n', '<leader>hp', gs.preview_hunk, { desc = "Git: hunkをプレビュー" })

        -- 差分プレビュー（Inline）- カーソル行の下に差分を展開
        map('n', '<leader>hP', gs.preview_hunk_inline, { desc = "Git: hunkをインライン表示" })

      end
    })
  end,
}
