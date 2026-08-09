# nvim-treeの右クリックメニューからgrug-farをフルスクリーンで開く

## 背景

nvim-treeで選択中のファイル/ディレクトリを対象に、grug-far（検索＆置換ツール）を直接開きたい。
Ctrl+Shift+Hで開くgrug-farは便利だが、パスを手動で入力する必要がある。
nvim-treeの右クリックメニューから直接、選択中のパスで検索を開始できると効率的。

## 実装の試行錯誤

### 試行1: 基本実装（問題あり）

```lua
function _G.NvimTreeSearchInPath()
  local api = require('nvim-tree.api')
  local node = api.tree.get_node_under_cursor()

  if not node then
    print('No node selected')
    return
  end

  local path = node.absolute_path
  require("grug-far").open({
    prefills = { paths = path }
  })
end
```

**問題点**: nvim-treeの左側の狭い領域でgrug-farが開いてしまう

### 試行2: 新しいタブで開く（問題あり）

```lua
function _G.NvimTreeSearchInPath()
  local api = require('nvim-tree.api')
  local node = api.tree.get_node_under_cursor()

  if not node then
    print('No node selected')
    return
  end

  local path = node.absolute_path
  vim.cmd("tabnew")  -- 新しいタブを作成
  require("grug-far").open({
    prefills = { paths = path }
  })
end
```

**問題点**:
- `tabnew`で空のバッファが生成される
- grug-farがデフォルトで垂直分割を作成する
- 結果: 余計なバッファが2つ生成される（左に2枚のタブ + 右ペインにも不要なバッファ）

### grug-far APIの仕様調査

AIS MCPで調査した結果:

1. **grug-farは常に垂直分割で開く**
   - これはプラグインの仕様で変更不可
   - `open()`に「フルスクリーンで開く」オプションは存在しない

2. **解決策: `wincmd o`（`:only`相当）を使用**
   - `open()`の後に`vim.cmd("wincmd o")`を実行
   - 現在のウィンドウ（grug-far）以外を閉じる

推奨パターン:
```lua
vim.cmd("tabnew")  -- 新タブ（空バッファ付き）
require("grug-far").open({ prefills = { paths = path } })  -- 垂直分割作成
vim.cmd("wincmd o")  -- 他のウィンドウを閉じる（grug-farのみ残る）
```

## 最終実装

```lua
-- nvim-treeで選択中のパスでgrug-farを開く関数
function _G.NvimTreeSearchInPath()
  local api = require('nvim-tree.api')
  local node = api.tree.get_node_under_cursor()

  if not node then
    print('No node selected')
    return
  end

  local path = node.absolute_path
  vim.cmd("tabnew")  -- 新しいタブを作成
  require("grug-far").open({
    prefills = { paths = path }
  })
  vim.cmd("wincmd o")  -- 他のウィンドウを閉じる（grug-farのみ残す）
end
```

右クリックメニューへの追加:
```lua
vim.cmd([[menu PopUp.-sep4- :]])
vim.cmd([[menu PopUp.Search\ &\ Replace\ in\ Path <Cmd>lua NvimTreeSearchInPath()<CR>]])
```

## 学んだこと

### 1. grug-farの仕様
- `open()`は常に垂直分割を作成する
- ウィンドウ配置を直接制御するオプションは存在しない
- レイアウト制御はVimコマンド（`tabnew`, `wincmd`など）で行う必要がある

### 2. `wincmd o`の活用
- `:only`と同じで、現在のウィンドウ以外を閉じる
- 余計なバッファ/ウィンドウを削除するのに有効
- タブ内の他のウィンドウのみが対象（他のタブには影響しない）

### 3. プラグインAPI調査の重要性
- ドキュメントやGitHub issuesを確認することで、仕様の制約を理解できる
- 「できないこと」を知ることで、適切な代替手段を見つけられる
- AIS MCPなどのツールを活用すると効率的

## ファイル

- `/Users/lilpacy/.config/nvim/lua/config/options.lua` (167-183行目, 227行目)

## 関連

- [nvim-tree file operations](nvim-tree-file-operations.md)
- grug-far.nvim: https://github.com/MagicDuck/grug-far.nvim
