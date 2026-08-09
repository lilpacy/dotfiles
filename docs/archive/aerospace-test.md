# AeroSpace 動作確認手順書

## 基本情報
- バージョン: 0.20.0-Beta
- 設定ファイル: `/Users/lilpacy/dotfiles/.aerospace.toml`
- ワークスペース: 1-9 (persistent)
- **注意**: macOSでは `alt` = `option (⌥)` キーです

## 1. 事前確認

```bash
# バージョン確認
aerospace --version

# 全ワークスペース一覧
aerospace list-workspaces --all

# 全ウィンドウ一覧
aerospace list-windows --all
```

## 2. ウィンドウフォーカス (option + hjkl)

- [ ] `option + h` - 左のウィンドウにフォーカス
- [ ] `option + j` - 下のウィンドウにフォーカス
- [ ] `option + k` - 上のウィンドウにフォーカス
- [ ] `option + l` - 右のウィンドウにフォーカス
- [ ] マウスがフォーカスしたモニターの中央に移動すること

## 3. ウィンドウスワップ (shift + option + hjkl)

- [ ] `shift + option + h` - 左のウィンドウと入れ替え
- [ ] `shift + option + j` - 下のウィンドウと入れ替え
- [ ] `shift + option + k` - 上のウィンドウと入れ替え
- [ ] `shift + option + l` - 右のウィンドウと入れ替え

## 4. ウィンドウ移動 (shift + cmd + hjkl)

- [ ] `shift + cmd + h` - 左に移動
- [ ] `shift + cmd + j` - 下に移動
- [ ] `shift + cmd + k` - 上に移動
- [ ] `shift + cmd + l` - 右に移動

## 5. ウィンドウリサイズ

### 大きくリサイズ (shift + option + wasd)
- [ ] `shift + option + w` - 上方向に拡大 (+50)
- [ ] `shift + option + s` - 下方向に縮小 (-50)
- [ ] `shift + option + a` - 左方向に縮小 (-50)
- [ ] `shift + option + d` - 右方向に拡大 (+50)

### 小さくリサイズ (shift + cmd + wasd)
- [ ] `shift + cmd + w` - 上方向に微調整 (+20)
- [ ] `shift + cmd + s` - 下方向に微調整 (-20)
- [ ] `shift + cmd + a` - 左方向に微調整 (-20)
- [ ] `shift + cmd + d` - 右方向に微調整 (+20)

## 6. レイアウト操作

- [ ] `option + e` - 分割方向を切り替え（horizontal ↔ vertical）
- [ ] `option + f` - フルスクリーン（外側のgapなし）
- [ ] `shift + option + f` - macOSネイティブフルスクリーン
- [ ] `option + t` - フロート ↔ タイリング切り替え

## 7. ワークスペース操作

### ワークスペース移動 (option + 数字)
- [ ] `option + 1` - ワークスペース 1 に移動
- [ ] `option + 2` - ワークスペース 2 に移動
- [ ] `option + 3` - ワークスペース 3 に移動
- [ ] `option + 4` - ワークスペース 4 に移動
- [ ] `option + 5` - ワークスペース 5 に移動
- [ ] `option + 6` - ワークスペース 6 に移動
- [ ] `option + 7` - ワークスペース 7 に移動
- [ ] `option + 8` - ワークスペース 8 に移動
- [ ] `option + 9` - ワークスペース 9 に移動

### ワークスペース間移動 (shift + option + 数字)
- [ ] `shift + option + 1` - 現在のウィンドウをワークスペース 1 に移動
- [ ] `shift + option + 2` - 現在のウィンドウをワークスペース 2 に移動
- [ ] `shift + option + 3` - 現在のウィンドウをワークスペース 3 に移動
- [ ] `shift + option + 4` - 現在のウィンドウをワークスペース 4 に移動
- [ ] `shift + option + 5` - 現在のウィンドウをワークスペース 5 に移動
- [ ] `shift + option + 6` - 現在のウィンドウをワークスペース 6 に移動
- [ ] `shift + option + 7` - 現在のウィンドウをワークスペース 7 に移動
- [ ] `shift + option + 8` - 現在のウィンドウをワークスペース 8 に移動
- [ ] `shift + option + 9` - 現在のウィンドウをワークスペース 9 に移動

### その他のワークスペース操作
- [ ] `option + tab` - 前のワークスペースに戻る（back-and-forth）

## 8. サービスモード (shift + option + ;)

- [ ] `shift + option + ;` - サービスモードに入る
- [ ] `esc` - 設定をリロード＆メインモードに戻る
- [ ] `r` - ワークスペースツリーをフラット化＆メインモードに戻る
- [ ] `f` - フロート/タイリング切り替え＆メインモードに戻る
- [ ] `backspace` - 現在のウィンドウ以外を全て閉じる＆メインモードに戻る

### サービスモード内でのjoin操作
- [ ] `shift + option + h` - 左のウィンドウと結合＆メインモードに戻る
- [ ] `shift + option + j` - 下のウィンドウと結合＆メインモードに戻る
- [ ] `shift + option + k` - 上のウィンドウと結合＆メインモードに戻る
- [ ] `shift + option + l` - 右のウィンドウと結合＆メインモードに戻る

## 9. アプリ別フロート設定確認

以下のアプリを開いたときに自動でフロート表示されることを確認：

- [ ] システム設定（System Settings / System Preferences）
- [ ] Arc Browser
- [ ] iTerm2
- [ ] Finder
- [ ] 1Password
- [ ] Alfred Preferences
- [ ] Preview
- [ ] Notes
- [ ] Raycast
- [ ] Screen Sharing
- [ ] ChatGPT
- [ ] Stickies
- [ ] OrbStack
- [ ] QuickTime Player
- [ ] NordVPN
- [ ] Claude

## 10. ギャップ（Gaps）の確認

- [ ] ウィンドウ間のギャップが10pxであること（inner.horizontal, inner.vertical）
- [ ] 画面端のギャップが10pxであること（outer.left, outer.bottom, outer.top, outer.right）

## 11. 正規化（Normalization）の確認

- [ ] ネストされたコンテナが自動的にフラット化されること
- [ ] ネストされたコンテナが反対方向を向くこと

## 12. トラブルシューティング

### 設定リロード
```bash
# サービスモードから: shift + option + ; → esc
# または手動で設定を再読み込み
```

### 現在の状態確認
```bash
# ワークスペース一覧
aerospace list-workspaces --all

# ウィンドウ一覧
aerospace list-windows --all
```
