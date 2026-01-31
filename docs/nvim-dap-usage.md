# nvim-dap 使い方

nvim-dapはNeovim用のDebug Adapter Protocol (DAP) クライアント。

## キーマップ

| キー | 説明 |
|------|------|
| `<leader>db` | ブレークポイントの設定/解除 |
| `<leader>dc` | デバッグ開始 / 実行継続 |
| `<leader>do` | ステップオーバー（次の行へ） |
| `<leader>di` | ステップイン（関数内へ） |
| `<leader>du` | DAP UIの表示/非表示 |

## 基本的なデバッグフロー

1. **ブレークポイント設定**: 停止したい行で `<leader>db`
2. **デバッグ開始**: `<leader>dc` でデバッグセッション開始
3. **ステップ実行**:
   - `<leader>do` で次の行へ（関数呼び出しはスキップ）
   - `<leader>di` で関数内部へ入る
4. **継続**: `<leader>dc` で次のブレークポイントまで実行
5. **UI確認**: `<leader>du` で変数やスタックを確認

## DAP UI パネル

`<leader>du` で開くUIには以下が含まれる：

- **Scopes**: ローカル変数、グローバル変数の値
- **Breakpoints**: 設定済みブレークポイント一覧
- **Stacks**: コールスタック
- **Watches**: ウォッチ式
- **REPL**: デバッグコンソール

## サポートしているランタイム

mason-nvim-dapにより自動インストール：
- **js-debug-adapter** (JavaScript/TypeScript/Node.js)

## JavaScript/TypeScriptのデバッグ

1. プロジェクトのルートで作業
2. デバッグしたいファイルを開く
3. ブレークポイントを設定
4. `<leader>dc` で開始

## Tips

- ブレークポイントは赤い丸印で表示される
- デバッグ開始時にDAP UIが自動で開く
- デバッグ終了時にDAP UIが自動で閉じる
- 条件付きブレークポイントは `:lua require("dap").set_breakpoint(condition)` で設定可能
