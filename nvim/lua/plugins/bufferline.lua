return {
  "akinsho/bufferline.nvim",
  version = "*",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("bufferline").setup({
      options = {
        mode = "buffers",
        diagnostics = "nvim_lsp",
        show_buffer_close_icons = false,
        show_close_icon = false,
        separator_style = "thin",
        -- バッファを削除してもウィンドウは保持（VSCodeライクな挙動）
        close_command = function(bufnr)
          require("bufdelete").bufdelete(bufnr, true)
        end,
        right_mouse_command = function(bufnr)
          require("bufdelete").bufdelete(bufnr, true)
        end,
        left_mouse_command = "buffer %d",
        offsets = {
          {
            filetype = "NvimTree",
            text = "File Explorer",
            highlight = "Directory",
            separator = true,
          },
        },
      },
    })

    -- キーマップ
    local opts = { noremap = true, silent = true }
    vim.keymap.set("n", "<S-l>", "<cmd>BufferLineCycleNext<CR>", opts)  -- 次のバッファ
    vim.keymap.set("n", "<S-h>", "<cmd>BufferLineCyclePrev<CR>", opts)  -- 前のバッファ
    vim.keymap.set("n", "<leader>x", "<cmd>BufferLinePickClose<CR>", opts)  -- バッファを選んで閉じる
    vim.keymap.set("n", "<leader>X", "<cmd>bdelete!<CR>", opts)  -- 現在のバッファを強制的に閉じる
  end,
}
