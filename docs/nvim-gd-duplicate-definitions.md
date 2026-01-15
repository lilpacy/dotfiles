# Neovim: gd で定義が重複して表示される問題

## 問題

TypeScript/TSXファイルで `gd` (go to definition) を使用すると、同じ定義が2つ表示される。

```
1  app/orders/[id]/products/page.tsx|40 col 20-31| const [quantity, setQuantity] = useState(1);
2  app/orders/[id]/products/page.tsx|40 col 20-31| const [quantity, setQuantity] = useState(1);
```

## 原因

`typescript-tools.nvim` と `ts_ls` (typescript-language-server) の2つのLSPクライアントが同じバッファにアタッチされており、両方が同じ定義を返すため。

`:LspInfo` で確認すると、Active Clientsに以下が表示される：
- `ts_ls` (id: 3)
- `typescript-tools` (id: 4)

Neovim 0.11の `vim.lsp.buf.definition()` は、バッファにアタッチされているすべてのLSPクライアントから結果を集めて表示するため、重複が発生する。

## 解決方法

### 1. typescript-tools以外のTypeScript LSPの定義ジャンプ機能を無効化

`nvim/lua/plugins/lsp.lua` の `on_attach` 関数に、競合するLSPクライアントの `definitionProvider` を無効化する処理を追加：

```lua
M.on_attach = function(client, bufnr)
  -- typescript-tools以外のTypeScript LSPは定義ジャンプを無効化（重複回避）
  if client.name == "tsserver"
    or client.name == "ts_ls"
    or client.name == "typescript-language-server"
    or client.name == "vtsls"
  then
    client.server_capabilities.definitionProvider = false
    client.server_capabilities.typeDefinitionProvider = false
  end

  -- 以下、通常のキーマップ設定...
end
```

### 2. ts_lsにカスタムon_attachを明示的に指定

`ts_ls` がデフォルトの `on_attach` を使わないよう、明示的にカスタム関数を指定：

```lua
-- ts_lsの定義ジャンプ機能を無効化（typescript-toolsと競合するため）
vim.lsp.config('ts_ls', {
  on_attach = M.on_attach,  -- カスタムon_attachを使用して、definitionProviderを無効化
  enabled = false,  -- 可能なら起動自体を無効化
})
```

### 3. typescript-toolsは共通のon_attachを使用

`nvim/lua/plugins/typescript-tools.lua` では、共通の `on_attach` を呼び出しつつ、TypeScript固有のキーマップを追加：

```lua
local on_attach = function(client, bufnr)
  -- 共通のLSPキーマップを適用
  if _G.lsp_on_attach then
    _G.lsp_on_attach(client, bufnr)
  end

  -- TypeScript固有のキーマップを追加
  local bufmap = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
  end

  bufmap('n', 'gs', '<cmd>TSToolsGoToSourceDefinition<CR>', 'ソース実装へジャンプ')
end
```

## 確認方法

1. Neovimを再起動
2. TypeScriptファイルを開く
3. `:LspInfo` で以下を確認：
   - `ts_ls` の `on_attach` が `@/Users/lilpacy/.config/nvim/lua/plugins/lsp.lua:4` になっている
   - `ts_ls` の `enabled: false` が表示されている
4. `gd` で定義ジャンプを試し、候補が1つだけ表示されることを確認

## 参考情報

- `typescript-tools.nvim` は `typescript-language-server` の置き換えであり、両方を同時に使用すべきではない
- Neovim 0.11の新しいLSP APIでは、`vim.lsp.config()` と `vim.lsp.enable()` を使用
- 複数のLSPクライアントが同じcapabilityを提供する場合、結果が重複する可能性がある

## 関連ファイル

- `/Users/lilpacy/dotfiles/nvim/lua/plugins/lsp.lua`
- `/Users/lilpacy/dotfiles/nvim/lua/plugins/typescript-tools.lua`
