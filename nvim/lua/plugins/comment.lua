return {
  "numToStr/Comment.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    require("Comment").setup({
      -- gc でコメント切り替え（行コメント）
      -- gb でブロックコメント
    })
  end,
}
