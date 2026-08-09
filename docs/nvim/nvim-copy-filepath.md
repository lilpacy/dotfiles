# Nvim ファイルパスコピー機能

Nvimで現在開いているファイルのパスをクリップボードにコピーするショートカット一覧。

## ノーマルモード（カーソル位置のファイル）

| ショートカット | 機能 | 例 |
|--------------|------|-----|
| `<leader>yf` | ファイル名のみ | `keymaps.lua` |
| `<leader>yr` | 相対パス | `nvim/lua/config/keymaps.lua` |
| `<leader>ya` | 絶対パス | `/Users/lilpacy/dotfiles/nvim/lua/config/keymaps.lua` |

## ビジュアルモード（選択範囲）

| ショートカット | 機能 | 例 |
|--------------|------|-----|
| `<leader>yc` | 絶対パス + 行番号 | `/Users/lilpacy/dotfiles/nvim/lua/config/keymaps.lua:15` |
|  |  | `/Users/lilpacy/dotfiles/nvim/lua/config/keymaps.lua:15-20` |

## 使用例

### ファイル名だけコピーしたい
```
1. ノーマルモードで <Space>yf
2. クリップボードに "keymaps.lua" がコピーされる
```

### プロジェクトルートからの相対パスをコピーしたい
```
1. ノーマルモードで <Space>yr
2. クリップボードに "nvim/lua/config/keymaps.lua" がコピーされる
```

### 絶対パスをコピーしたい
```
1. ノーマルモードで <Space>ya
2. クリップボードに "/Users/lilpacy/dotfiles/nvim/lua/config/keymaps.lua" がコピーされる
```

### コードの特定行を参照として共有したい
```
1. 対象行をビジュアル選択（V または v）
2. <Space>yc
3. クリップボードに "/path/to/file.lua:15-20" がコピーされる
```

## 設定ファイル

`nvim/lua/config/keymaps.lua` で定義されています。

## 関連情報

- VSCodeの `Cmd+K P` (相対パスコピー) に相当する機能
- leaderキーは `<Space>` に設定済み
- クリップボードはシステムクリップボード (`+` レジスタ) を使用
