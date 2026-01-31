return {
  "folke/persistence.nvim",
  event = "BufReadPre",
  opts = {},
  keys = {
    { "<leader>qs", function() require("persistence").load() end, desc = "Restore Session" },
    { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
  },
}
