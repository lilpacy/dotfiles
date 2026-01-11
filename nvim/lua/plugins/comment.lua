return {
  "numToStr/Comment.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local comment = require("Comment")
    comment.setup({
      -- gc でコメント切り替え（行コメント）
      -- gb でブロックコメント
    })

    local api = require("Comment.api")
    vim.keymap.set("n", "<C-_>", api.toggle.linewise.current, {
      desc = "Toggle comment (VSCode style)",
    })

    local esc = vim.api.nvim_replace_termcodes("<ESC>", true, false, true)
    vim.keymap.set("x", "<C-_>", function()
      vim.api.nvim_feedkeys(esc, "nx", false)
      api.toggle.linewise(vim.fn.visualmode())
    end, {
      desc = "Toggle comment (VSCode style)",
    })
  end,
}
