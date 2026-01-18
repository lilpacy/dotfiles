# tmux display-popup 設定

tmux 3.2+ で使える `display-popup` 機能のショートカット設定。

## 設定内容

`.tmux.conf` に以下のキーバインドを追加:

```tmux
# ===== display-popup keybindings =====

# Prefix + P (Shift+p): 基本的なポップアップターミナル（90% x 80%、中央）
bind-key P display-popup -E -x C -y C -w 90% -h 80% -d "#{pane_current_path}"

# Prefix + g: lazygit をポップアップで開く
bind-key g display-popup -E -x C -y C -w 95% -h 95% -d "#{pane_current_path}" "lazygit"

# Prefix + s: lazysql をポップアップで開く
bind-key s display-popup -E -x C -y C -w 95% -h 95% -d "#{pane_current_path}" "lazysql"

# Prefix + f: fzfファイル検索をポップアップで開く（選択したファイルをエディタで開く）
bind-key f display-popup -E -x C -y C -w 90% -h 80% -d "#{pane_current_path}" "nvim \$(fzf)"
```

## ショートカット一覧

| キー | 機能 | サイズ |
|------|------|--------|
| `Prefix + P` (Shift+p) | ポップアップターミナル（シェル） | 90% × 80% |
| `Prefix + g` | lazygit | 95% × 95% |
| `Prefix + s` | lazysql | 95% × 95% |
| `Prefix + f` | fzf ファイル検索 → nvim で開く | 90% × 80% |

## ポップアップの閉じ方

1. **`exit` または `Ctrl-d`** - シェルを終了
2. **コマンド終了で自動で閉じる** - `-E` オプションにより、lazygit や fzf を終了（`q` など）すると自動で閉じる

## オプション説明

- `-E`: コマンド終了時にポップアップを自動で閉じる
- `-x C -y C`: 画面中央に表示
- `-w 90% -h 80%`: 幅90%、高さ80%
- `-d "#{pane_current_path}"`: カレントディレクトリで開く

## 設定の反映

```sh
tmux source-file ~/.tmux.conf
```

または tmux 内で `Prefix + :` → `source-file ~/.tmux.conf`

## 参考

- [tmux(1) - Linux manual page](https://man7.org/linux/man-pages/man1/tmux.1.html)
- tmux 3.2+ で `display-popup` コマンドが追加
