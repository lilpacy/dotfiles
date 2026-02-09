-- lua/config/keymaps.lua
-- グローバルなキーマップ設定

local map = vim.keymap.set

-- :q でバッファが複数あれば現在のバッファだけ閉じる（VSCodeライクな挙動）
local function smart_quit(bang)
  -- 1. 同一タブにウィンドウが複数ある → 素の :q（ウィンドウを閉じる）
  local wins = vim.api.nvim_tabpage_list_wins(0)
  if #wins > 1 then
    vim.cmd(bang and "q!" or "q")
    return
  end

  -- 2. 特殊バッファ（help, quickfix, terminal等） → 素の :q
  local bt = vim.bo.buftype
  if bt ~= "" and bt ~= "acwrite" then
    vim.cmd(bang and "q!" or "q")
    return
  end

  -- 3. 通常バッファの数をカウント
  local listed = vim.fn.getbufinfo({ buflisted = 1 })
  local normal_count = 0
  for _, info in ipairs(listed) do
    local bt_i = vim.bo[info.bufnr].buftype
    if bt_i == "" or bt_i == "acwrite" then
      normal_count = normal_count + 1
    end
  end

  if normal_count > 1 then
    -- 複数バッファあり → 現在のバッファだけ閉じる
    require("bufdelete").bufdelete(0, bang)
  else
    -- 最後の1つ → Neovim終了
    vim.cmd(bang and "q!" or "q")
  end
end

map("n", "<leader>q", function()
  smart_quit(false)
end, { desc = "Close buffer" })

vim.api.nvim_create_user_command("Bq", function(opts)
  smart_quit(opts.bang)
end, { bang = true, desc = "Close buffer or quit if last" })

-- :q → :Bq に変換（:qa, :wq 等には影響しない）
vim.cmd([[cnoreabbrev <expr> q getcmdtype() == ':' && getcmdline() ==# 'q' ? 'Bq' : 'q']])

-- :Q もsmart_quitに統一
vim.api.nvim_create_user_command("Q", function(opts)
  smart_quit(opts.bang)
end, { bang = true, desc = "Close buffer or quit if last" })

-- ファイルパス系コピー（ノーマルモード）
-- ファイル名のみ
map("n", "<leader>yf", function()
  local filename = vim.fn.expand("%:t")
  vim.fn.setreg("+", filename)
  print("Copied filename: " .. filename)
end, { desc = "Yank filename" })

-- 相対パス
map("n", "<leader>yr", function()
  local filepath = vim.fn.expand("%")
  vim.fn.setreg("+", filepath)
  print("Copied relative path: " .. filepath)
end, { desc = "Yank relative path" })

-- 絶対パス
map("n", "<leader>ya", function()
  local filepath = vim.fn.expand("%:p")
  vim.fn.setreg("+", filepath)
  print("Copied absolute path: " .. filepath)
end, { desc = "Yank absolute path" })

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
