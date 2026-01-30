# Neovim 0.11 markdownクラッシュ問題と解決策

## 問題
Neovim 0.11でmarkdownファイルを開くとクラッシュする。

## 根本原因
**Neovim 0.11の非同期Treesitterパース**がmarkdownパーサとの組み合わせでバグを引き起こしていた。

## 解決策
`init.lua`の先頭に以下を追加：

```lua
vim.g._ts_force_sync_parsing = true
```

これでTreesitterの非同期パースが無効化され、クラッシュが解消される。

## 補足：markdownパーサの再インストール
問題が発生した場合、パーサの再インストールも有効：

```vim
:TSUninstall markdown markdown_inline
:TSInstall markdown markdown_inline
```

## 影響を受けていたプラグイン
非同期パースバグにより、以下のプラグインがmarkdownで問題を起こしていた（全て解消済み）：
- treesitter（markdownハイライト）
- snacks.nvim（画像機能）
- render-markdown.nvim
- aerial.nvim（markdownバックエンド）

## 調査経緯
1. `nvim -u NONE file.md`でプラグインなしなら開ける → プラグインが原因
2. 二分探索でtreesitterが原因と特定
3. AIS MCPに相談 → 非同期パース無効化を提案
4. `vim.g._ts_force_sync_parsing = true`で全プラグイン復活

## 参考
- Neovim 0.11のTreesitter非同期パースに関するバグ報告多数
- Reddit: https://www.reddit.com/r/neovim/comments/1jtz99h
