-- ============================================
-- Code Folding Cheatsheet
-- ============================================
-- Ctrl+Enter : toggle fold under cursor
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

    map("n", "<C-CR>", "za", { desc = "Toggle fold" })

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
