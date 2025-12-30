-- true color対応
vim.opt.termguicolors = true

-- クリップボード連携を有効化
vim.opt.clipboard = "unnamedplus"

-- その他の基本設定
vim.opt.number = true          -- 行番号を表示
vim.opt.relativenumber = false -- 相対行番号を無効化
vim.opt.expandtab = true      -- タブをスペースに変換
vim.opt.shiftwidth = 2        -- インデント幅
vim.opt.tabstop = 2           -- タブ幅
vim.opt.mouse = "a"           -- すべてのモードでマウスを有効化

-- netrw設定
vim.g.netrw_liststyle = 3     -- ツリービュー形式

-- 外部変更の自動反映
vim.opt.autoread = true         -- ファイルが外部で変更されたら自動で読み込み
vim.opt.updatetime = 100        -- 変更検知を早くする（デフォルトは4000ms）

-- ファイル変更を自動的にチェック
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  pattern = "*",
  command = "checktime",
  desc = "外部変更を自動検知"
})

-- tmuxのフォーカスに応じて背景色を変更
vim.api.nvim_create_autocmd("FocusGained", {
  pattern = "*",
  callback = function()
    vim.cmd("highlight Normal guibg=NONE ctermbg=NONE")
  end,
  desc = "フォーカス時に背景色をクリア"
})

vim.api.nvim_create_autocmd("FocusLost", {
  pattern = "*",
  callback = function()
    vim.cmd("highlight Normal guibg=NONE ctermbg=NONE")
  end,
  desc = "フォーカス喪失時も背景色をクリア"
})

-- insertモードを抜けた時に自動保存
vim.api.nvim_create_autocmd("InsertLeave", {
  pattern = "*",
  callback = function()
    if vim.bo.modified and vim.fn.expand("%") ~= "" then
      vim.cmd("silent! write")
    end
  end,
  desc = "InsertLeave時に自動保存"
})

-- normalモードでテキスト変更時（ペースト等）に自動保存
vim.api.nvim_create_autocmd("TextChanged", {
  pattern = "*",
  callback = function()
    if vim.bo.modified and vim.fn.expand("%") ~= "" then
      vim.cmd("silent! write")
    end
  end,
  desc = "TextChanged時に自動保存"
})

-- 100ms操作がなければ自動保存
vim.api.nvim_create_autocmd("CursorHold", {
  pattern = "*",
  callback = function()
    if vim.bo.modified and vim.fn.expand("%") ~= "" then
      vim.cmd("silent! write")
    end
  end,
  desc = "CursorHold時に自動保存"
})

-- バッファを離れる時、フォーカス喪失時に自動保存
vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost" }, {
  pattern = "*",
  callback = function()
    if vim.bo.modified and vim.fn.expand("%") ~= "" then
      vim.cmd("silent! write")
    end
  end,
  desc = "BufLeave/FocusLost時に自動保存"
})
