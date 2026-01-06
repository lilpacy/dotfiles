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
vim.opt.fileformat = "unix"   -- 改行コードをLF（Unix形式）に
vim.opt.fileformats = { "unix", "dos" }  -- 優先順位: unix > dos

-- CRLF/CRを自動的にLFに変換
vim.api.nvim_create_autocmd("BufReadPost", {
  pattern = "*",
  callback = function()
    local lines_with_cr = vim.fn.search('\\r$', 'nw')
    if lines_with_cr > 0 then
      vim.cmd([[silent! %s/\r$//e]])
      vim.bo.fileformat = "unix"
      vim.bo.bomb = false
    end
  end,
  desc = "CRLF/CRを自動的にLFに変換"
})

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

-- =============================================
-- 右クリックメニュー (PopUp) の設定
-- =============================================

-- デフォルトメニューをクリア
vim.cmd([[aunmenu PopUp]])

-- LSP関連
vim.cmd([[menu PopUp.Go\ to\ Definition <Cmd>lua vim.lsp.buf.definition()<CR>]])
vim.cmd([[menu PopUp.Go\ to\ Implementation <Cmd>lua vim.lsp.buf.implementation()<CR>]])
vim.cmd([[menu PopUp.Find\ References <Cmd>lua vim.lsp.buf.references()<CR>]])
vim.cmd([[menu PopUp.-sep1- :]])
vim.cmd([[menu PopUp.Rename <Cmd>lua vim.lsp.buf.rename()<CR>]])
vim.cmd([[menu PopUp.Code\ Action <Cmd>lua vim.lsp.buf.code_action()<CR>]])
vim.cmd([[menu PopUp.Format <Cmd>lua vim.lsp.buf.format({ async = true })<CR>]])

-- Git関連
vim.cmd([[menu PopUp.-sep2- :]])
vim.cmd([[menu PopUp.Git:\ Blame\ Line <Cmd>Gitsigns blame_line<CR>]])
vim.cmd([[menu PopUp.Git:\ Stage\ Hunk <Cmd>Gitsigns stage_hunk<CR>]])
vim.cmd([[menu PopUp.Git:\ Reset\ Hunk <Cmd>Gitsigns reset_hunk<CR>]])
vim.cmd([[menu PopUp.Git:\ Preview\ Hunk <Cmd>Gitsigns preview_hunk<CR>]])

-- 検索
vim.cmd([[menu PopUp.-sep3- :]])
vim.cmd([[menu PopUp.Search\ in\ Workspace <Cmd>lua require('telescope.builtin').grep_string()<CR>]])

-- コメント
vim.cmd([[menu PopUp.-sep4- :]])
vim.cmd([[menu PopUp.Toggle\ Comment <Cmd>lua require('Comment.api').toggle.linewise.current()<CR>]])
vim.cmd([[vmenu PopUp.Toggle\ Comment <Esc><Cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>]])
