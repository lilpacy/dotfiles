# nvim-tree ウィンドウ幅の問題と解決策

## 問題の発見

nvim-treeのウィンドウ幅が期待と異なる挙動を示していた。

### 症状
1. nvim-tree(30%) | ファイル(70%) の状態
2. `:q` でファイルウィンドウを閉じる → nvim-treeが画面全体(100%)になる
3. 再度ファイルを開く → nvim-tree(50%) | ファイル(50%) になってしまう

### 期待される動作
- 常にnvim-treeは30幅で固定
- 手動で`:vertical resize`した場合のみ、その幅を保持

### 副次的な問題
`:q`でファイルウィンドウを閉じると、bufferlineに`[No Name]`という空のバッファが表示される。

## 原因調査

### 1. Git履歴の確認
コミット `fac6e1b` で以下の設定を追加していたことが判明:

```lua
view = {
  width = 30,
  side = "left",
  preserve_window_proportions = true, -- 幅を変更したら保持する
},
actions = {
  open_file = {
    quit_on_open = false,
    resize_window = false, -- 手動で変更した幅を保持する
  },
},
```

### 2. AIS MCPへの相談結果

詳細な分析により、以下の問題が明らかになった:

#### nvim-tree設定の誤解
- `preserve_window_proportions = true`: レイアウト再計算時に現在の比率を維持しようとする
  - ファイルを閉じて全幅になった状態も「保持すべき比率」として記憶される
- `resize_window = false`: ファイルを開くときに`view.width`に戻さない
  - これらの組み合わせで、50:50の比率が維持されてしまっていた

#### 正しい設定の理解
- `preserve_window_proportions`: **nvim-tree以外のウィンドウ**の比率を保持するオプション
  - サイドバー固定には`true`が適切
- `resize_window`: ファイルを開くときにnvim-treeを`view.width`に合わせるかどうか
  - 常に30幅に戻したい場合は`true`が必要

#### [No Name]バッファの原因
- bufdelete.nvimが「最後の実ファイルバッファを削除してもウィンドウを保持する」ために空バッファを自動生成する仕様
- nvim-treeの幅問題とは本質的に別問題

## 解決策の実装

### 1. nvim-tree.luaの設定を正しく修正

```lua
view = {
  width = 30,
  side = "left",
  preserve_window_proportions = true, -- nvim-tree以外のウィンドウ比率を保持
},
actions = {
  open_file = {
    quit_on_open = false,
    resize_window = true, -- ファイルを開くときにview.widthに合わせる
  },
},
```

### 2. winfixwidthの追加

`:wincmd =`などの自動等分でnvim-treeの幅が勝手に変わらないように固定:

```lua
-- nvim-treeの幅を固定（:wincmd =などで自動変更されないように）
vim.api.nvim_create_autocmd("FileType", {
  pattern = "NvimTree",
  callback = function()
    vim.cmd("setlocal winfixwidth")
  end,
})
```

### 3. WinResizedイベントの改善

1ウィンドウのみの場合(nvim-treeが全幅になる時)は手動変更とみなさないように修正:

```lua
-- nvim-treeの幅が手動で変更されたときに保存
-- 1ウィンドウのみの場合(treeが全幅になる)は手動変更とみなさない
vim.api.nvim_create_autocmd("WinResized", {
  callback = function()
    -- 1つしかウィンドウがないときは無視
    local wins = vim.api.nvim_tabpage_list_wins(0)
    if #wins <= 1 then
      return
    end

    local winid = vim.api.nvim_get_current_win()
    local bufnr = vim.api.nvim_win_get_buf(winid)
    local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })

    if ft == "NvimTree" then
      local width = vim.api.nvim_win_get_width(winid)
      _G.nvim_tree_manual_width = width
    end
  end,
})
```

### 4. bufferlineのcustom_filterを強化

`modified`フラグではなく実際のバッファ内容を確認して、完全に空の`[No Name]`のみを非表示に:

```lua
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
```

## 最終的な動作

1. nvim-tree(30) | ファイル(残り全部)
2. `:q`でファイルを閉じる → nvim-treeが全幅になる
3. 再度ファイルを開く → nvim-tree(30) | ファイル(残り全部) に戻る
4. `:vertical resize 40`で手動変更 → その幅が保持される
5. 空の`[No Name]`バッファはbufferlineに表示されない

## リセットコマンド

手動で変更した幅をデフォルト(30)に戻すコマンドも用意:

```vim
:NvimTreeResetWidth
```

## 学んだこと

1. **nvim-treeの設定の意味を正しく理解する重要性**
   - `preserve_window_proportions`と`resize_window`の役割を誤解していた
   - ドキュメントを丁寧に読むか、AIに相談して正しい理解を得ることが重要

2. **WinResizedイベントの扱い方**
   - あらゆるウィンドウサイズ変更で発火するため、条件分岐が必要
   - 「1ウィンドウのみ」の場合を除外することで誤記憶を防げる

3. **問題の切り分け**
   - nvim-treeの幅問題と[No Name]バッファ問題は本質的に別問題
   - 両方を同時に解決しようとせず、それぞれに適切な対処をする

4. **bufdelete.nvimの仕様理解**
   - 「最後のバッファを削除してもウィンドウを保持する」ための空バッファ生成は仕様
   - bufferlineの`custom_filter`で対処するのが適切

## 参考資料

- nvim-tree.lua documentation
- AIS MCP (GPT-5 reasoning) による詳細な分析
- コミット `fac6e1b`: 最初の試み
- コミット `9867bf3`: bufdelete.nvim導入時の変更
