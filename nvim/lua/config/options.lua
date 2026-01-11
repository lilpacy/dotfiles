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

-- =============================================
-- nvim-tree用の右クリックメニュー
-- =============================================

-- ファイル内容をクリップボードにコピーする関数
function _G.NvimTreeCopyFileContent()
  local api = require('nvim-tree.api')
  local node = api.tree.get_node_under_cursor()

  if not node or node.type ~= 'file' then
    print('Not a file')
    return
  end

  local filepath = node.absolute_path
  local file = io.open(filepath, 'r')

  if not file then
    print('Failed to read file: ' .. node.name)
    return
  end

  local content = file:read('*all')
  file:close()

  vim.fn.setreg('+', content)
  print('Copied file content: ' .. node.name)
end

-- nvim-treeで選択中のパスでgrug-farを開く関数
function _G.NvimTreeSearchInPath()
  local tree_api = require('nvim-tree.api')
  local node = tree_api.tree.get_node_under_cursor()

  if not node then
    print('No node selected')
    return
  end

  local path = node.absolute_path
  vim.cmd("tab split")  -- 現在のウィンドウを新しいタブに複製（空バッファを作らない）
  require("grug-far").open({
    prefills = { paths = path },
    transient = true,  -- 一時的なバッファとして扱う
  })
  vim.cmd("wincmd o")  -- 他のウィンドウを閉じる

  -- 名前なしの未変更バッファをbufferlineから隠す
  local api = vim.api
  for _, bufnr in ipairs(api.nvim_list_bufs()) do
    if api.nvim_buf_is_valid(bufnr) and api.nvim_buf_is_loaded(bufnr) then
      local name = api.nvim_buf_get_name(bufnr)
      local modified = api.nvim_get_option_value("modified", { buf = bufnr })
      if name == "" and not modified then
        api.nvim_set_option_value("buflisted", false, { buf = bufnr })
      end
    end
  end
end

-- バッファタイプに応じてメニューを動的に切り替える
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*",
  callback = function()
    -- 現在のバッファがnvim-treeかどうかを判定
    local ft = vim.bo.filetype

    if ft == "NvimTree" then
      -- nvim-tree用メニューに切り替え
      vim.cmd([[aunmenu PopUp]])

      -- ファイルパスコピー
      vim.cmd([[menu PopUp.Copy\ Filename <Cmd>lua require('nvim-tree.api').fs.copy.filename()<CR>]])
      vim.cmd([[menu PopUp.Copy\ Relative\ Path <Cmd>lua require('nvim-tree.api').fs.copy.relative_path()<CR>]])
      vim.cmd([[menu PopUp.Copy\ Absolute\ Path <Cmd>lua require('nvim-tree.api').fs.copy.absolute_path()<CR>]])

      -- ファイル内容コピー
      vim.cmd([[menu PopUp.Copy\ File\ Content <Cmd>lua NvimTreeCopyFileContent()<CR>]])

      vim.cmd([[menu PopUp.-sep1- :]])

      -- ファイル操作
      vim.cmd([[menu PopUp.Open <Cmd>lua require('nvim-tree.api').node.open.edit()<CR>]])
      vim.cmd([[menu PopUp.Open\ in\ Vertical\ Split <Cmd>lua require('nvim-tree.api').node.open.vertical()<CR>]])
      vim.cmd([[menu PopUp.Open\ in\ Horizontal\ Split <Cmd>lua require('nvim-tree.api').node.open.horizontal()<CR>]])
      vim.cmd([[menu PopUp.Open\ in\ New\ Tab <Cmd>lua require('nvim-tree.api').node.open.tab()<CR>]])

      vim.cmd([[menu PopUp.-sep2- :]])

      -- 編集
      vim.cmd([[menu PopUp.Rename <Cmd>lua require('nvim-tree.api').fs.rename()<CR>]])
      vim.cmd([[menu PopUp.Delete <Cmd>lua require('nvim-tree.api').fs.remove()<CR>]])
      vim.cmd([[menu PopUp.Create\ File/Directory <Cmd>lua require('nvim-tree.api').fs.create()<CR>]])

      vim.cmd([[menu PopUp.-sep3- :]])

      -- カット/コピー/ペースト
      vim.cmd([[menu PopUp.Cut <Cmd>lua require('nvim-tree.api').fs.cut()<CR>]])
      vim.cmd([[menu PopUp.Copy <Cmd>lua require('nvim-tree.api').fs.copy.node()<CR>]])
      vim.cmd([[menu PopUp.Paste <Cmd>lua require('nvim-tree.api').fs.paste()<CR>]])

      vim.cmd([[menu PopUp.-sep4- :]])

      -- 検索
      vim.cmd([[menu PopUp.Search\ &\ Replace\ in\ Path <Cmd>lua NvimTreeSearchInPath()<CR>]])
    else
      -- 通常のバッファ用メニューに戻す
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
    end
  end,
  desc = "バッファタイプに応じて右クリックメニューを切り替え"
})
