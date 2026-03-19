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
  keys = {
    -- Intuitive shortcuts
    { "<Tab>", "za", desc = "Toggle fold" },
    { "<S-Tab>", function()
      local ufo = require("ufo")
      -- foldlevel=0 means all closed → open, otherwise close
      if vim.wo.foldlevel == 0 then
        ufo.openAllFolds()
      else
        ufo.closeAllFolds()
      end
    end, desc = "Toggle all folds" },
    { "K", function()
      local winid = require("ufo").peekFoldedLinesUnderCursor()
      if not winid then
        vim.lsp.buf.hover()
      end
    end, desc = "Peek fold or hover" },

    -- Standard z-commands (remapped to ufo for consistency)
    { "zR", function() require("ufo").openAllFolds() end, desc = "Open all folds" },
    { "zM", function() require("ufo").closeAllFolds() end, desc = "Close all folds" },
    { "zr", function() require("ufo").openFoldsExceptKinds() end, desc = "Reduce folding" },
    { "zm", function() require("ufo").closeFoldsWith() end, desc = "Fold more" },
  },
  opts = {
    provider_selector = function()
      return { "treesitter", "indent" }
    end,
  },
}
