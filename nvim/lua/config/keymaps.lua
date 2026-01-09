-- lua/config/keymaps.lua
-- グローバルなキーマップ設定

local map = vim.keymap.set

-- Visual選択範囲のファイルパス:行番号をクリップボードにコピー
map("v", "<leader>yc", function()
  local start_line = vim.fn.line("v")
  local end_line = vim.fn.line(".")

  -- 選択が逆の場合もあるので、小さい方を開始行にする
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end

  local filepath = vim.fn.expand("%:p")  -- 絶対パス

  local result
  if start_line == end_line then
    result = string.format("%s:%d", filepath, start_line)
  else
    result = string.format("%s:%d-%d", filepath, start_line, end_line)
  end

  vim.fn.setreg("+", result)
  print("Copied: " .. result)
end, { desc = "Copy file:line reference to clipboard" })
