# Nvim診断キーマップ

LSP診断（エラー・警告）を操作するためのキーマップを追加。

## 追加したキーマップ

| キー | 動作 | 詳細 |
|------|------|------|
| `gl` | 診断をフロートで表示 | カーソル行の診断メッセージをフロートウィンドウで表示 |
| `[d` | 前の診断へ | ファイル内の前の診断（エラー・警告）へジャンプ |
| `]d` | 次の診断へ | ファイル内の次の診断（エラー・警告）へジャンプ |

## 実装場所

`/Users/lilpacy/dotfiles/nvim/lua/plugins/lsp.lua`

`M.on_attach`関数内（64-67行目）に以下を追加：

```lua
-- 診断（Diagnostics）
bufmap('n', 'gl', vim.diagnostic.open_float, '診断をフロートで表示')
bufmap('n', '[d', vim.diagnostic.goto_prev, '前の診断へ')
bufmap('n', ']d', vim.diagnostic.goto_next, '次の診断へ')
```

## 使用方法

1. エラーや警告が表示されているファイルを開く
2. `gl`でカーソル行の詳細な診断メッセージを表示
3. `[d`/`]d`で診断間を移動

## 背景

LSPの診断機能を効率的に使うため、VSCode風のキーマップを追加。
`gl`はVSCodeの"Show hover"的な役割、`[d`/`]d`はVimの標準的な前後移動パターン（`[`/`]`プレフィックス）に従っている。
