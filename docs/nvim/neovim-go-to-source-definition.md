# Neovim: Go to Source Definition 設定

## 背景・課題

TypeScriptでコードジャンプ（`gd`）を使うと、`.d.ts`型定義ファイルまでは辿れるが、そこから`gi`（Go to Implementation）を押してもライブラリの実際のJavaScript/TypeScript実装コードに辿れない。

### なぜ `gi` では辿れないのか

- `vim.lsp.buf.implementation` はLSP標準の `textDocument/implementation` を呼ぶ
- これは「インターフェースを実装しているクラス」を探すためのもの
- `.d.ts` → 実装 `.js/.ts` へ飛ぶ用途ではない（仕様が違う）

## 解決策

### typescript-tools.nvim を使用

`pmizio/typescript-tools.nvim` は tsserver に直接通信するTypeScript専用クライアント。VSCodeと同等の「Go to Source Definition」機能を提供する。

### 設定ファイル

`lua/plugins/typescript-tools.lua` を作成:

```lua
return {
  "pmizio/typescript-tools.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "neovim/nvim-lspconfig",
  },
  ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
  config = function()
    local on_attach = function(client, bufnr)
      local bufmap = function(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
      end

      -- Go to Source Definition (ライブラリ実装へジャンプ)
      bufmap('n', 'gs', '<cmd>TSToolsGoToSourceDefinition<CR>', 'ソース実装へジャンプ')

      -- 他のキーマップも必要に応じて追加
    end

    require("typescript-tools").setup({
      on_attach = on_attach,
      settings = {
        tsserver_file_preferences = {
          includeInlayParameterNameHints = "all",
          -- 他の設定...
        },
      },
    })
  end,
}
```

### lsp.lua の変更

`ts_ls` を削除（typescript-tools.nvimに移行するため）:

```lua
-- ensure_installed から ts_ls を削除
ensure_installed = {
  "lua_ls",
  -- "ts_ls", -- 削除
  "tailwindcss",
  "eslint",
  "jsonls",
},

-- vim.lsp.enable から ts_ls を削除
vim.lsp.enable({ 'lua_ls', 'tailwindcss', 'eslint', 'jsonls', 'clangd' })
```

## キーマップ

| キー | 動作 |
|------|------|
| `gd` | 定義へジャンプ（`.d.ts`まで） |
| `gs` | ソース実装へジャンプ（`.js`/`.ts`の実装コード） |
| `gi` | 実装へジャンプ（interface → class） |
| `gr` | 参照を表示 |
| `gt` | 型定義へジャンプ |

## 制限事項

- TypeScript 4.7以上が必要
- ライブラリがソースコードを npm パッケージに同梱している必要がある
- `@types/xxx` のような型定義のみのパッケージでは飛べない
- `declarationMap: true` でビルドされたライブラリはより正確にジャンプ可能

## 代替手段

### 方法1: ts_ls + カスタム関数

typescript-tools.nvim を使わず、ts_ls の `_typescript.goToSourceDefinition` を直接呼ぶ方法:

```lua
local function goto_source_definition()
  local params = vim.lsp.util.make_position_params()
  vim.lsp.buf.execute_command({
    command = '_typescript.goToSourceDefinition',
    arguments = { params.textDocument.uri, params.position },
  })
end

vim.keymap.set('n', 'gs', goto_source_definition, { buffer = bufnr })
```

※ `handlers['workspace/executeCommand']` でレスポンスを処理する必要がある

### 方法2: vtsls + nvim-vtsls

VSCodeのTypeScript拡張をラップしたLSP。大規模プロジェクトで高速。

```lua
require('vtsls').commands.goto_source_definition(0)
```

## 参考

- [typescript-tools.nvim](https://github.com/pmizio/typescript-tools.nvim)
- [vtsls](https://github.com/yioneko/vtsls)
- [TypeScript 4.7 - Go To Source Definition](https://devblogs.microsoft.com/typescript/announcing-typescript-4-7/)
