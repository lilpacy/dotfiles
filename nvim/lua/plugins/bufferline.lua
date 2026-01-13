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
        -- 空の[No Name]バッファを非表示
        custom_filter = function(bufnr)
          local name = vim.api.nvim_buf_get_name(bufnr)
          local ft = vim.bo[bufnr].filetype
          local bt = vim.bo[bufnr].buftype

          -- NvimTree自体は非表示
          if ft == "NvimTree" then
            return false
          end

          -- 完全に空のノーマルバッファ([No Name])は非表示
          if name == "" and bt == "" then
            local line_count = vim.api.nvim_buf_line_count(bufnr)
            if line_count == 1 then
              local line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] or ""
              if line == "" then
                return false
              end
            elseif line_count == 0 then
              return false
            end
          end

          return true
        end,
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
