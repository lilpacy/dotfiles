return {
  "nvim-telescope/telescope.nvim",
  tag = "v0.2.0",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
  },
  keys = {
    -- VSCode style keybindings (Ctrl instead of Cmd for terminal)
    { "<C-p>", "<cmd>Telescope find_files<cr>", desc = "Quick Open (Cmd+P)" },
    { "<C-S-p>", "<cmd>Telescope commands<cr>", desc = "Command Palette (Cmd+Shift+P)" },
    { "<C-S-f>", "<cmd>Telescope live_grep<cr>", desc = "Search in Files (Cmd+Shift+F)" },
    { "<C-S-e>", "<cmd>Telescope buffers<cr>", desc = "Explorer/Buffers (Cmd+Shift+E)" },
    { "<C-S-o>", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Go to Symbol (Cmd+Shift+O)" },
    { "<C-t>", "<cmd>Telescope lsp_workspace_symbols<cr>", desc = "Go to Symbol in Workspace (Cmd+T)" },
    -- Additional useful mappings
    { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
    { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
    { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent files" },
    { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
  },
  config = function()
    local actions = require("telescope.actions")
    require("telescope").setup({
      defaults = {
        file_ignore_patterns = { "node_modules", ".git/" },
        mappings = {
          i = {
            ["<Esc>"] = actions.close,  -- VSCode: Esc closes immediately
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-u>"] = false,  -- Clear line like VSCode
          },
        },
      },
    })
    require("telescope").load_extension("fzf")
  end,
}
