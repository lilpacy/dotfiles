# trouble.nvim v3 使い方

診断・参照・Quickfix結果を統一UIで表示するプラグイン。

## キーマップ

| キー | 説明 |
|------|------|
| `<leader>xx` | プロジェクト全体の診断一覧を表示/非表示 |
| `<leader>xX` | 現在のバッファの診断のみ表示 |
| `<leader>cs` | シンボル一覧（関数・変数など）を表示 |

## Troubleウィンドウ内の操作

| キー | 説明 |
|------|------|
| `<CR>` / `<Tab>` | 項目にジャンプ |
| `o` | ジャンプしてTroubleを閉じる |
| `q` | Troubleを閉じる |
| `j` / `k` | 次/前の項目に移動 |
| `<C-x>` | 水平分割で開く |
| `<C-v>` | 垂直分割で開く |
| `P` | プレビュー表示 |
| `r` | リフレッシュ |

## コマンド

```vim
:Trouble diagnostics       " 診断一覧
:Trouble symbols           " シンボル一覧
:Trouble lsp_references    " LSP参照一覧
:Trouble lsp_definitions   " LSP定義一覧
:Trouble quickfix          " Quickfixリスト
:Trouble loclist           " ロケーションリスト
```

## フィルタ例

```vim
:Trouble diagnostics filter.buf=0           " 現在バッファのみ
:Trouble diagnostics filter.severity=ERROR  " エラーのみ
```
