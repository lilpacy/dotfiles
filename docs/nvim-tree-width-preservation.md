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

---

## 2026-01-16: 手動変更した幅が保存されない問題の修正

### 問題の再発見

コミット `5c780a4` で実装した幅保存の仕組みが、実際には動作していなかった。
- `:vertical resize 40` で手動変更しても、次回開いたときに30に戻ってしまう

### 根本原因の特定

3つの処理が競合していた:

```
1. resize_window = true → ファイルを開くたびに30幅に自動調整
2. BufWinEnter → 保存された幅（例: 40）に復元
3. WinResized → その変更を「手動変更」として保存

問題の流れ:
ユーザーが :vertical resize 40 で変更
↓
WinResized発火 → _G.nvim_tree_manual_width = 40 保存 ✓
↓
ファイルを開く or nvim-tree再オープン
↓
resize_window=true または BufWinEnter により幅が調整される
↓
WinResized発火 → _G.nvim_tree_manual_width が上書きされる ✗
```

**核心**: `WinResized`イベントは「手動変更」と「自動復元・自動調整」を区別できないため、自動変更も手動変更として記録されてしまっていた。

### 解決策の実装

#### 1. 自動復元中フラグの導入

```lua
-- 自動復元中かどうかのフラグ（自動復元中のWinResizedを無視するため）
_G.nvim_tree_restoring_width = false
```

#### 2. WinResizedイベントでフラグをチェック

```lua
vim.api.nvim_create_autocmd("WinResized", {
  callback = function()
    -- 自動復元中は無視
    if _G.nvim_tree_restoring_width then
      return
    end

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

#### 3. BufWinEnterで復元前後にフラグ制御

```lua
vim.api.nvim_create_autocmd("BufWinEnter", {
  pattern = "NvimTree_*",
  callback = function()
    -- 自動復元中フラグを立てる
    _G.nvim_tree_restoring_width = true

    local winid = vim.api.nvim_get_current_win()
    local width = _G.nvim_tree_manual_width or 30
    vim.api.nvim_win_set_width(winid, width)

    -- 復元後、少し待ってからフラグを下ろす
    vim.schedule(function()
      _G.nvim_tree_restoring_width = false
    end)
  end,
})
```

#### 4. resize_windowをfalseに戻す

`BufWinEnter`で幅を復元するため、nvim-tree内部の自動調整（`resize_window`）は不要:

```lua
actions = {
  open_file = {
    quit_on_open = false,
    resize_window = false, -- BufWinEnterで復元するため、ここでは自動調整しない
    window_picker = {
      enable = true,
    },
  },
},
```

### 修正後の動作

1. nvim-tree(30) | ファイル(残り全部)
2. `:vertical resize 40`で手動変更
3. nvim-treeを閉じて再度開く → **40幅が保持される** ✓
4. ファイルを開く → 40幅が維持される ✓
5. `:NvimTreeResetWidth`でデフォルト(30)に戻せる

### 学んだこと

1. **イベントベースの自動化における状態管理の重要性**
   - `WinResized`のような汎用イベントは、意図しない場面でも発火する
   - 「手動変更」と「自動変更」を区別するには、明示的なフラグ管理が必要

2. **競合する自動化処理の排除**
   - `resize_window = true`と`BufWinEnter`による復元は同じ目的を持つ
   - 両方を有効にすると、どちらが優先されるか不明確になり、バグの原因になる
   - 1つの責務は1つの仕組みで実装する（BufWinEnterに一元化）

3. **vim.schedule()の活用**
   - 非同期処理でフラグを下ろすことで、復元処理が確実に完了してからWinResizedを受け付けるようにできる

### 関連コミット

- コミット `5c780a4`: 最初の幅保存実装（問題あり）
- コミット（今回）: フラグによる自動変更の除外
