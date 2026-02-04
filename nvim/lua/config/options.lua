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

-- 自動保存可能かチェック（バイナリ・特殊バッファ・画像等を除外）
local function can_autosave()
  if not vim.bo.modified then return false end
  if vim.fn.expand("%") == "" then return false end
  if vim.bo.buftype ~= "" then return false end
  if vim.bo.readonly or not vim.bo.modifiable then return false end
  if vim.bo.binary then return false end
  local fname = vim.api.nvim_buf_get_name(0)
  if fname == "" or vim.fn.filereadable(fname) == 0 then return false end
  local ft = vim.bo.filetype
  if ft == "gitcommit" or ft == "gitrebase" then return false end
  local ext = vim.fn.expand("%:e"):lower()
  local exclude_ext = { "gif", "png", "jpg", "jpeg", "webp", "bmp", "ico", "svg", "pdf", "exe", "dll", "so", "dylib" }
  if vim.tbl_contains(exclude_ext, ext) then return false end
  return true
end

-- insertモードを抜けた時に自動保存
vim.api.nvim_create_autocmd("InsertLeave", {
  pattern = "*",
  callback = function()
    if can_autosave() then
      vim.cmd("silent! write")
    end
  end,
  desc = "InsertLeave時に自動保存"
})

-- normalモードでテキスト変更時（ペースト等）に自動保存
vim.api.nvim_create_autocmd("TextChanged", {
  pattern = "*",
  callback = function()
    if can_autosave() then
      vim.cmd("silent! write")
    end
  end,
  desc = "TextChanged時に自動保存"
})

-- 100ms操作がなければ自動保存
vim.api.nvim_create_autocmd("CursorHold", {
  pattern = "*",
  callback = function()
    if can_autosave() then
      vim.cmd("silent! write")
    end
  end,
  desc = "CursorHold時に自動保存"
})

-- バッファを離れる時、フォーカス喪失時に自動保存
vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost" }, {
  pattern = "*",
  callback = function()
    if can_autosave() then
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
-- neo-tree用の右クリックメニュー
-- =============================================

-- neo-tree用ヘルパー関数
local function get_neo_tree_state()
  local ok, manager = pcall(require, "neo-tree.sources.manager")
  if not ok then return nil end
  return manager.get_state("filesystem")
end

local function get_neo_tree_node()
  local state = get_neo_tree_state()
  if state and state.tree then
    return state.tree:get_node()
  end
  return nil
end

-- ファイル内容をクリップボードにコピーする関数
function _G.NeoTreeCopyFileContent()
  local node = get_neo_tree_node()

  if not node or node.type ~= 'file' then
    print('Not a file')
    return
  end

  local filepath = node:get_id()
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

-- neo-treeで選択中のパスをFinderで開く関数
function _G.NeoTreeOpenInFinder()
  local node = get_neo_tree_node()

  if not node then
    print('No node selected')
    return
  end

  local path = node:get_id()
  if node.type == 'file' then
    vim.fn.system({ 'open', '-R', path })
  else
    vim.fn.system({ 'open', path })
  end
end

-- neo-treeで選択中のパスでlazygitをtmux popupで開く関数
function _G.NeoTreeOpenLazygit()
  local node = get_neo_tree_node()

  if not node then
    print('No node selected')
    return
  end

  if vim.env.TMUX == nil then
    print('Not inside tmux')
    return
  end

  local path = node:get_id()
  if node.type == 'file' then
    path = vim.fn.fnamemodify(path, ':h')
  end

  vim.fn.system({
    'tmux', 'display-popup',
    '-E',
    '-d', path,
    '-w', '90%',
    '-h', '90%',
    'lazygit'
  })
end

-- neo-treeで選択中のパスのリポジトリをwebで開く関数
function _G.NeoTreeOpenRepoInWeb()
  local node = get_neo_tree_node()

  if not node then
    print('No node selected')
    return
  end

  local path = node:get_id()
  if node.type == 'file' then
    path = vim.fn.fnamemodify(path, ':h')
  end

  vim.fn.jobstart('cd ' .. vim.fn.shellescape(path) .. ' && gh repo view --web', { detach = true })
end

-- neo-treeで選択中のパスでgrug-farを開く関数
function _G.NeoTreeSearchInPath()
  local node = get_neo_tree_node()

  if not node then
    print('No node selected')
    return
  end

  local path = node:get_id()
  vim.cmd("tab split")
  require("grug-far").open({
    prefills = { paths = path },
    transient = true,
  })
  vim.cmd("wincmd o")

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

-- neo-tree用コピー関数
function _G.NeoTreeCopyFilename()
  local node = get_neo_tree_node()
  if node then
    vim.fn.setreg('+', node.name)
    print('Copied: ' .. node.name)
  end
end

function _G.NeoTreeCopyRelativePath()
  local node = get_neo_tree_node()
  if node then
    local rel = vim.fn.fnamemodify(node:get_id(), ':.')
    vim.fn.setreg('+', rel)
    print('Copied: ' .. rel)
  end
end

function _G.NeoTreeCopyAbsolutePath()
  local node = get_neo_tree_node()
  if node then
    vim.fn.setreg('+', node:get_id())
    print('Copied: ' .. node:get_id())
  end
end

-- バッファタイプに応じてメニューを動的に切り替える
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*",
  callback = function()
    local ft = vim.bo.filetype

    if ft == "neo-tree" then
      -- neo-tree用メニューに切り替え
      vim.cmd([[aunmenu PopUp]])

      -- ファイルパスコピー
      vim.cmd([[menu PopUp.Copy\ Filename <Cmd>lua NeoTreeCopyFilename()<CR>]])
      vim.cmd([[menu PopUp.Copy\ Relative\ Path <Cmd>lua NeoTreeCopyRelativePath()<CR>]])
      vim.cmd([[menu PopUp.Copy\ Absolute\ Path <Cmd>lua NeoTreeCopyAbsolutePath()<CR>]])

      -- ファイル内容コピー
      vim.cmd([[menu PopUp.Copy\ File\ Content <Cmd>lua NeoTreeCopyFileContent()<CR>]])

      vim.cmd([[menu PopUp.-sep1- :]])

      -- ファイル操作
      vim.cmd([[menu PopUp.Open <Cmd>Neotree action=show reveal_force_cwd<CR>]])
      vim.cmd([[menu PopUp.Open\ in\ Vertical\ Split <Cmd>lua require("neo-tree.sources.common.commands").open_vsplit(require("neo-tree.sources.manager").get_state("filesystem"))<CR>]])
      vim.cmd([[menu PopUp.Open\ in\ Horizontal\ Split <Cmd>lua require("neo-tree.sources.common.commands").open_split(require("neo-tree.sources.manager").get_state("filesystem"))<CR>]])
      vim.cmd([[menu PopUp.Open\ in\ New\ Tab <Cmd>lua require("neo-tree.sources.common.commands").open_tabnew(require("neo-tree.sources.manager").get_state("filesystem"))<CR>]])

      vim.cmd([[menu PopUp.-sep2- :]])

      -- 編集
      vim.cmd([[menu PopUp.Rename <Cmd>lua require("neo-tree.sources.filesystem.commands").rename(require("neo-tree.sources.manager").get_state("filesystem"))<CR>]])
      vim.cmd([[menu PopUp.Delete <Cmd>lua require("neo-tree.sources.filesystem.commands").delete(require("neo-tree.sources.manager").get_state("filesystem"))<CR>]])
      vim.cmd([[menu PopUp.Create\ File/Directory <Cmd>lua require("neo-tree.sources.filesystem.commands").add(require("neo-tree.sources.manager").get_state("filesystem"))<CR>]])

      vim.cmd([[menu PopUp.-sep3- :]])

      -- カット/コピー/ペースト
      vim.cmd([[menu PopUp.Cut <Cmd>lua require("neo-tree.sources.filesystem.commands").cut_to_clipboard(require("neo-tree.sources.manager").get_state("filesystem"))<CR>]])
      vim.cmd([[menu PopUp.Copy <Cmd>lua require("neo-tree.sources.filesystem.commands").copy_to_clipboard(require("neo-tree.sources.manager").get_state("filesystem"))<CR>]])
      vim.cmd([[menu PopUp.Paste <Cmd>lua require("neo-tree.sources.filesystem.commands").paste_from_clipboard(require("neo-tree.sources.manager").get_state("filesystem"))<CR>]])

      vim.cmd([[menu PopUp.-sep4- :]])

      -- 検索
      vim.cmd([[menu PopUp.Search\ &\ Replace\ in\ Path <Cmd>lua NeoTreeSearchInPath()<CR>]])

      vim.cmd([[menu PopUp.-sep5- :]])

      -- Finderで開く
      vim.cmd([[menu PopUp.Open\ in\ Finder <Cmd>lua NeoTreeOpenInFinder()<CR>]])

      -- Lazygitを開く
      vim.cmd([[menu PopUp.Open\ Lazygit <Cmd>lua NeoTreeOpenLazygit()<CR>]])

      -- リポジトリをWebで開く
      vim.cmd([[menu PopUp.Open\ Repo\ in\ Web <Cmd>lua NeoTreeOpenRepoInWeb()<CR>]])
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
