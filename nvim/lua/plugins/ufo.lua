-- ============================================
-- Code Folding Cheatsheet
-- ============================================
-- Tab        : toggle fold under cursor
-- Shift+Tab  : toggle all folds (open/close)
-- K          : peek folded lines (or LSP hover)
--
-- Standard z-commands also work:
--   za/zo/zc  : toggle/open/close
--   zR/zM     : open all / close all
--   zj/zk     : next / prev fold
-- ============================================

return {
  "kevinhwang91/nvim-ufo",
  dependencies = { "kevinhwang91/promise-async" },
  event = "BufReadPost",
  config = function()
    require("ufo").setup({
      provider_selector = function()
        return { "treesitter", "indent" }
      end,
    })

    local ufo = require("ufo")
    local map = vim.keymap.set

    -- Intuitive shortcuts
    map("n", "<Tab>", "za", { desc = "Toggle fold" })
    map("n", "<S-Tab>", function()
      if vim.wo.foldlevel == 0 then
        ufo.openAllFolds()
      else
        ufo.closeAllFolds()
      end
    end, { desc = "Toggle all folds" })
    map("n", "K", function()
      local winid = ufo.peekFoldedLinesUnderCursor()
      if not winid then
        vim.lsp.buf.hover()
      end
    end, { desc = "Peek fold or hover" })

    -- Standard z-commands (remapped to ufo for consistency)
    map("n", "zR", ufo.openAllFolds, { desc = "Open all folds" })
    map("n", "zM", ufo.closeAllFolds, { desc = "Close all folds" })
    map("n", "zr", ufo.openFoldsExceptKinds, { desc = "Reduce folding" })
    map("n", "zm", ufo.closeFoldsWith, { desc = "Fold more" })
  end,
}
