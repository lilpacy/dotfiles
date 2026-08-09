# Herdr/tmux 移行ガイド

作成日: 2026-07-13

この文書は、これまで tmux + Ghostty でやっていた作業を、移行後の Ghostty + Herdr でどう操作するかの対応表です。設計上の目的は、tmux を Herdr 上に再現することではなく、複数プロジェクトを開きっぱなしにして一覧・移動・復元できる作業体験を Herdr の workspace 中心に移すことです。

## 最初にやること

1. Ghostty を完全に終了して、起動し直す。
2. 新しく開いた Ghostty で Herdr が起動することを確認する。
3. 画面左の sidebar、または `Ctrl+B` → `w` で workspace 一覧を確認する。
4. 既存のプロジェクトを開くときは、Herdr 内で `herdrw open <path>` を使う。

現在の設定では、Ghostty の top-level shell だけが Herdr に入ります。Herdr 内の pane、Codex、SSH、Conductor、tmux 内では自動起動しません。

## 基本モデル

| tmux での考え方 | Herdr での考え方 |
| --- | --- |
| tmux session | Herdr shared session。通常は `HERDR_SHARED_SESSION=work`、未指定なら `work` |
| tmux window | Herdr workspace |
| window 名 | workspace label |
| window の cwd | workspace の project directory |
| window 内の pane | workspace 内の pane |
| window 内で別作業単位を作る | workspace 内の tab |
| 下部 window bar | Herdr sidebar + workspace picker |
| window state save/restore | Herdr native snapshot restore + `herdrw save/restore` |

## よく使う操作の対応表

`prefix` はどちらも `Ctrl+B` です。

| やりたいこと | tmux での操作 | Herdr/Ghostty での操作 |
| --- | --- | --- |
| 起動時に作業環境へ入る | Ghostty 起動時に `.zshrc` が `tmux attach/new` | Ghostty 起動時に `.zshrc` が `herdrp` で Herdr shared session へ入る |
| 開いているプロジェクト一覧を見る | 下部 window bar | 左 sidebar、または `prefix` → `w` |
| プロジェクトへ移動する | `prefix` → window 番号 | `prefix` → `shift+1..9`、または `prefix` → `w` |
| 直前の作業単位へ戻る | `prefix` → `p` | tab なら `prefix` → `p`、workspace は sidebar/picker か `prefix` → `shift+1..9` |
| 現在のフォルダで新しい作業単位を作る | `prefix` → `c` で new window | `prefix` → `c` で current workspace 内に new tab |
| 別プロジェクトを開く | `cd <path>` して window 作成 | `herdrw open <path>` |
| ghq + peco で移動 | `Ctrl+]` で `cd <repo>` | Herdr 内では `Ctrl+]` が `herdrw open <repo>` を入力する |
| pane を左右上下に移動 | `prefix` → `h/j/k/l` | 同じ |
| pane を zoom | `prefix` → `z` | 同じ |
| pane を resize | `prefix` → `H/J/K/L` | `prefix` → `r` で Herdr resize mode |
| 縦方向に分割 | `prefix` → `"` | `prefix` → `"` |
| 横方向に分割 | `prefix` → `%` | `prefix` → `%` |
| tab を番号で切り替える | window 番号 | `prefix` → `1..9` |
| workspace を番号で切り替える | window 番号 | `prefix` → `shift+1..9` |
| sidebar 表示切替 | tmux には該当なし | `prefix` → `b` |
| detach | `prefix` → `q` 相当の detach 運用 | `prefix` → `q` |

## popup 系操作の対応表

tmux の `display-popup` と完全に同じ見た目は再現していません。Herdr では temporary pane として開きます。各コマンドは現在の pane cwd に明示的に `cd` してから起動します。

| やりたいこと | tmux での操作 | Herdr での操作 |
| --- | --- | --- |
| 一時 shell | `prefix` → `P` | `prefix` → `P` |
| lazygit | `prefix` → `g` | `prefix` → `g` |
| lazysql | `prefix` → `s` | `prefix` → `s` |
| nvim | `prefix` → `v` | `prefix` → `v` |
| top | `prefix` → `t` | `prefix` → `t` |
| fzf で選んだファイルを nvim | `prefix` → `f` | `prefix` → `f` |
| tmux profile | `prefix` → `C` | `prefix` → `C` で `herdrw save` と `herdrw list` を表示 |

## nvim の右クリックメニュー

nvim 内の右クリックメニューは tmux の pane 右クリックメニューとは別物です。Herdr の通常右クリックも使うため、`mouse_capture = true` のままにし、`right_click_passthrough_modifier = "alt"` で Option/Alt + 右クリックだけ nvim へ渡します。

| やりたいこと | tmux 環境 | Herdr/Ghostty 環境 |
| --- | --- | --- |
| 通常バッファの LSP/Git/Comment メニューを開く | nvim 上で右クリック | 同じ |
| nvim-tree 左サイドバーのファイル操作メニューを開く | nvim-tree 上で右クリック | Option/Alt + 右クリック |
| ファイルを single click で開く | nvim-tree 上で左クリック | 同じ |
| Herdr の pane UI/menu を mouse で操作する | tmux pane UI | 通常の右クリック |
| tmux の custom pane menu を開く | tmux pane 上で右クリック | Herdr の通常右クリック menu を使う |

## helper command

| コマンド | 用途 |
| --- | --- |
| `herdrp` | Ghostty / zsh から安全に Herdr shared session へ入る |
| `herdrw list` | 現在開いている workspace を表示する |
| `herdrw open [path]` | path の workspace を focus。なければ作成する |
| `herdrw save` | workspace history を保存する |
| `herdrw restore` | workspace history から workspace set を復元する |

`herdrw` は Herdr server や user session を stop/delete しません。

## 再起動後の復元

Herdr 自体が server restart 後に workspaces, tabs, panes, cwd, layout, focus を snapshot restore します。PC 再起動後に running shell、dev server、test process までは復元されません。

補助として `herdrw save` / `herdrw restore` も使えます。保存対象は session、保存時刻、workspace label、canonical path、active workspace path です。復元時にディレクトリが消えていた場合はスキップし、勝手に `$HOME` へ置き換えません。

## 移行後にやらないこと

| tmux でやっていたこと | Herdr での扱い |
| --- | --- |
| tmux bottom statusline の完全再現 | しない。sidebar / picker / indexed switch に置き換える |
| tmux copy-mode vi keymap + `pbcopy` | しない。`prefix` → `e` の scrollback edit と terminal/editor copy を使う |
| mouse drag copy の tmux 連携 | しない。terminal native selection を使う |
| right-click custom pane menu | tmux 固有の menu は移植しない。Herdr 通常右クリックと、Option/Alt + 右クリックで nvim menu を使い分ける |
| focus-follows-mouse | 明示設定なし。keyboard focus と通常 mouse UI を使う |
| image passthrough | 今回は移植しない |
| tmux hook による window state save/restore | Herdr snapshot restore と `herdrw save/restore` に置き換える |
| `tmux-dev-layout` / `tmux-dev-layout2` | 旧 Herdr layout helper は削除済み。必要になったら実測して別途設計する |

## 困ったとき

Herdr に入っているか確認:

```sh
echo "$HERDR_SESSION"
```

開いている workspace を確認:

```sh
herdrw list
```

現在のディレクトリを workspace として開く:

```sh
herdrw open .
```

最後に保存された workspace set を復元:

```sh
herdrw restore
```
