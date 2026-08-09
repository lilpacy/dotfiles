# nvim-tree: マウスリサイズ時のクリック誤動作対策

## 問題

nvim-treeの幅をマウスドラッグでリサイズすると、ドラッグ終了時（ボタンを離した瞬間）に`<LeftRelease>`イベントが発火し、意図せずファイル/フォルダが開閉してしまう。

## 原因

シングルクリックで開く設定として`<LeftRelease>`をマッピングしていたため：

```lua
vim.keymap.set('n', '<LeftRelease>', api.node.open.edit, opts('Open with single click'))
```

リサイズのドラッグ終了時にもこのイベントが発火してしまう。

## 解決策

### 採用した方法: vim.on_key() + exprマッピング

**重要な発見**: `<LeftMouse>`をマッピングすると、分割線上のクリックもマッピングに横取りされ、Neovimのデフォルトのリサイズ処理が実行されなくなる。

**解決策**: `vim.on_key()`で`<LeftMouse>`と`<LeftDrag>`を監視するだけにして、マッピングはしない。`<LeftRelease>`だけをexprマッピングで制御する。

```lua
-- config関数内でグローバルに設定

-- マウス状態の初期化
if not _G.nvim_tree_mouse_state then
  _G.nvim_tree_mouse_state = { press = nil }
end

-- vim.on_key で<LeftMouse>と<LeftDrag>を監視（マッピングはしない）
if not _G.nvim_tree_mouse_listener_registered then
  _G.nvim_tree_mouse_listener_registered = true
  vim.on_key(function(char)
    local key = vim.fn.keytrans(char)

    -- nvim-tree バッファ以外では無視
    local buf = vim.api.nvim_get_current_buf()
    if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].filetype ~= 'NvimTree' then
      return
    end

    if key == '<LeftMouse>' then
      local m = vim.fn.getmousepos()
      _G.nvim_tree_mouse_state.press = {
        winid = m.winid,
        line = m.line,
        column = m.column,
        time = vim.loop.now(),
        dragged = false,
      }
    elseif key == '<LeftDrag>' then
      if _G.nvim_tree_mouse_state.press then
        _G.nvim_tree_mouse_state.press.dragged = true
      end
    end
  end, vim.api.nvim_create_namespace('nvim-tree-mouse-watch'))
end
```

```lua
-- on_attach関数内で<LeftRelease>のみマッピング

vim.keymap.set('n', '<LeftRelease>', function()
  local press = _G.nvim_tree_mouse_state.press
  _G.nvim_tree_mouse_state.press = nil

  -- このバッファ上での押下イベントがなければデフォルト動作
  if not press then
    return '<LeftRelease>'
  end

  -- ドラッグが発生していたらデフォルト動作（リサイズなど）
  if press.dragged then
    return '<LeftRelease>'
  end

  local m = vim.fn.getmousepos()

  -- 押下時と別ウィンドウで離された場合はデフォルト動作
  if m.winid ~= press.winid then
    return '<LeftRelease>'
  end

  -- 分割線やステータスラインで離した場合はデフォルト動作
  if m.line == 0 or m.column == 0 then
    return '<LeftRelease>'
  end

  -- 移動量が大きければドラッグとみなしてデフォルト動作
  local dline = math.abs(m.line - press.line)
  local dcolumn = math.abs(m.column - press.column)
  if dline + dcolumn > 1 then
    return '<LeftRelease>'
  end

  -- 押下から離すまでの時間が長いものをドラッグ扱い
  local dt = vim.loop.now() - press.time
  if dt > 500 then
    return '<LeftRelease>'
  end

  -- ここまで来たら「ほぼその場でのクリック」とみなし、ノードを開く
  -- exprマッピング内ではバッファ変更ができないのでvim.schedule()で非同期実行
  vim.schedule(function()
    api.node.open.edit()
  end)
  return '' -- 処理済みなので<LeftRelease>をVimに渡さない
end, vim.tbl_extend('force', opts('Open with single click'), { expr = true, replace_keycodes = false }))
```

### 仕組み

1. **`vim.on_key()`で監視**: `<LeftMouse>`と`<LeftDrag>`をマッピングせず、監視だけする
   - マッピングしないので、分割線でのリサイズ機能が壊れない
   - Neovimのデフォルト動作（カーソル移動、リサイズ）がそのまま動く

2. **`<LeftRelease>`だけexprマッピング**: クリックかドラッグかを判定
   - ドラッグだった → `'<LeftRelease>'`を返してNeovimに処理を任せる
   - クリックだった → `vim.schedule()`で`api.node.open.edit()`を非同期実行して空文字を返す

3. **`vim.schedule()`の必要性**: exprマッピング内ではバッファ/ウィンドウ変更ができない
   - 直接`api.node.open.edit()`を呼ぶと `E565: Not allowed to change text or change window` エラー
   - `vim.schedule()`で次のイベントループに遅延実行することで回避

### 判定条件

- 押下記録なし → リサイズ操作として無視
- `dragged`フラグがtrue → ドラッグ操作として無視
- 押下時と別ウィンドウ → 無視
- 位置が1px以上移動 → ドラッグとして無視
- 500ms以上経過 → 長押しドラッグとして無視
- それ以外 → シングルクリックとして`api.node.open.edit()`実行

### 試行錯誤の経緯（不採用案）

#### 1. ダブルクリックに変更

```lua
vim.keymap.set('n', '<2-LeftMouse>', api.node.open.edit, opts('Open with double click'))
```

- **利点**: シンプル、リサイズ操作と完全に分離
- **欠点**: シングルクリックという操作性が失われる

#### 2. `<LeftMouse>`をマッピング

```lua
vim.keymap.set('n', '<LeftMouse>', function()
  -- 位置記録...
end, opts('Record mouse press'))
```

- **問題**: `<LeftMouse>`をバッファローカルマッピングすると、分割線クリックも奪ってしまい、リサイズが壊れる

#### 3. exprマッピングで`<LeftMouse>`を返す

```lua
vim.keymap.set('n', '<LeftMouse>', function()
  return '<LeftMouse>'
end, { expr = true })
```

- **問題**: カーソルがクリック位置に移動しない

#### 4. 通常のマッピングで`nvim_win_set_cursor()`

```lua
vim.keymap.set('n', '<LeftMouse>', function()
  local m = vim.fn.getmousepos()
  vim.api.nvim_win_set_cursor(m.winid, { m.line, m.column - 1 })
end)
```

- **問題**: 分割線でのリサイズが壊れる

## 動作確認

- **リサイズ**: `<LeftMouse>`をマッピングしていないのでNeovimのデフォルト動作が維持される ✓
- **シングルクリック**: カーソル移動後、ファイル/フォルダが開く ✓
- **ドラッグ操作**: `dragged`フラグまたは移動量で検知して無視 ✓

## 参照

- 実装: `nvim/lua/plugins/nvim-tree.lua` (config関数 + on_attach関数内)
- 関連API: `vim.on_key()`, `vim.fn.getmousepos()`, `vim.loop.now()`, `vim.schedule()`
