-- クリップボード連携を有効化
vim.opt.clipboard = "unnamedplus"

-- その他の基本設定
vim.opt.number = true          -- 行番号を表示
vim.opt.relativenumber = false -- 相対行番号を無効化
vim.opt.expandtab = true      -- タブをスペースに変換
vim.opt.shiftwidth = 2        -- インデント幅
vim.opt.tabstop = 2           -- タブ幅

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

-- 自動保存
vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave", "CursorHold" }, {
  pattern = "*",
  callback = function()
    if vim.bo.modified and vim.fn.filereadable(vim.fn.expand("%")) == 1 and not vim.bo.readonly then
      vim.cmd("silent! write")
    end
  end,
  desc = "変更を自動保存"
})
