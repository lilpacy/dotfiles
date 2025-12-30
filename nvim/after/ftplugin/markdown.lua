-- Markdown専用の設定

-- 折り返しを見やすく
vim.opt_local.wrap = true
vim.opt_local.linebreak = true  -- 単語途中で折り返さない

-- Treesitterベースのフォールディング
vim.opt_local.foldmethod = "expr"
vim.opt_local.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt_local.foldlevel = 99  -- デフォルトで全て開いた状態

-- チェックボックスのトグル: <leader>x
vim.keymap.set("n", "<leader>x", function()
  local line = vim.api.nvim_get_current_line()
  if line:match("%- %[ %]") then
    line = line:gsub("%- %[ %]", "- [x]", 1)
  elseif line:match("%- %[x%]") then
    line = line:gsub("%- %[x%]", "- [ ]", 1)
  end
  vim.api.nvim_set_current_line(line)
end, { buffer = true, silent = true, desc = "Toggle checkbox" })
