# nvim-tree から neo-tree への移行ガイド

2026-02-05 に nvim-tree から neo-tree へ移行した。

## 結論: ユーザー体験はほぼ変わらない

移行後も以下の機能はすべてそのまま使える:
- キーマッピング（`<C-n>`, `<CR>`, `t`, `v`, `o`, `-`, `%`, `d`, `D`, `R` など）
- 右クリックメニュー（全項目）
- シングルクリックでファイルを開く
- マウスドラッグでのウィンドウリサイズ
- 自動フォーカス追従
- 手動変更した幅の保持

## 変更点一覧

### コマンド

| 操作 | nvim-tree | neo-tree |
|------|-----------|----------|
| トグル | `:NvimTreeToggle` | `:Neotree toggle` |
| 幅リセット | `:NvimTreeResetWidth` | `:NeoTreeResetWidth` |

**注意**: `<C-n>` でのトグルは変わらず動作する。

### キーマッピング（変更なし）

| キー | 機能 |
|------|------|
| `<C-n>` | ツリーのトグル |
| `<CR>` または シングルクリック | ファイルを開く |
| `t` | 新しいタブで開く |
| `v` | 垂直分割で開く |
| `o` | 水平分割で開く |
| `-` | 親ディレクトリに移動 |
| `%` | 新しいファイル作成 |
| `d` | 新しいディレクトリ作成 |
| `D` | 削除 |
| `R` | リネーム |
| `x` | カット |
| `c` | コピー |
| `p` | ペースト |
| `<C-S-h>` | grug-farで検索・置換 |

### 右クリックメニュー（変更なし）

#### neo-tree上での右クリック
- Copy Filename / Relative Path / Absolute Path / File Content
- Open / Open in Vertical Split / Horizontal Split / New Tab
- Rename / Delete / Create File/Directory
- Cut / Copy / Paste
- Search & Replace in Path（grug-far連携）
- Open in Finder
- Open Lazygit（tmux popup）
- Open Repo in Web（GitHub）

#### 通常バッファでの右クリック
- LSP機能（Go to Definition / Implementation / References / Rename / Code Action / Format）
- Git機能（Blame / Stage Hunk / Reset Hunk / Preview Hunk）
- Search in Workspace
- Toggle Comment

## 内部的な変更（開発者向け）

### 設定ファイル

| 項目 | 変更前 | 変更後 |
|------|--------|--------|
| プラグイン設定 | `nvim/lua/plugins/nvim-tree.lua` | `nvim/lua/plugins/neo-tree.lua` |
| グローバル関数 | `NvimTree*()` | `NeoTree*()` |
| filetype | `NvimTree` | `neo-tree` |

### API の違い

| 操作 | nvim-tree | neo-tree |
|------|-----------|----------|
| ノード取得 | `api.tree.get_node_under_cursor()` | `state.tree:get_node()` |
| パス取得 | `node.absolute_path` | `node:get_id()` |
| 状態取得 | `require('nvim-tree.api')` | `require('neo-tree.sources.manager').get_state('filesystem')` |

### グローバル変数

| 変更前 | 変更後 |
|--------|--------|
| `_G.nvim_tree_manual_width` | `_G.neo_tree_manual_width` |
| `_G.nvim_tree_mouse_state` | `_G.neo_tree_mouse_state` |

## 移行した理由

- neo-tree の方がメンテナンスが活発
- より柔軟なカスタマイズが可能
- nui.nvim を使った modern な UI

## トラブルシューティング

### 以前の nvim-tree が残っている場合

lazy.nvim のキャッシュをクリアして再起動:

```bash
rm -rf ~/.local/share/nvim/lazy/nvim-tree.lua
nvim
```

### 右クリックメニューが動作しない場合

options.lua の filetype 判定が `neo-tree` になっているか確認:

```lua
if ft == "neo-tree" then
  -- ...
end
```

## 関連ドキュメント

以下のドキュメントは nvim-tree 時代の実装詳細として参照用に残している:
- [nvim-tree-file-operations.md](nvim-tree-file-operations.md)
- [nvim-tree-auto-focus.md](nvim-tree-auto-focus.md)
- [nvim-tree-grug-far-fullscreen.md](nvim-tree-grug-far-fullscreen.md)
- [nvim-tree-mouse-click-resize.md](nvim-tree-mouse-click-resize.md)
- [nvim-tree-width-preservation.md](nvim-tree-width-preservation.md)

neo-tree でも同等の機能を実装済み。実装の考え方は同じ。
