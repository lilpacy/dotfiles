# Herdr/tmux 移行要件

作成日: 2026-07-12

この文書は、tmux 運用から Herdr へ移行するために、今回の会話で出てきた要件を一旦集約したもの。ここに書いてある内容は実装案ではなく、次の planning / Fable review / Codex review / 実装の入力として扱う。

実装後の使い方と tmux 操作から Herdr/Ghostty 操作への対応表は [Herdr/tmux 移行ガイド](./herdr-tmux-migration-guide.md) を参照する。

## 目的

tmux のコマンドや見た目をそのまま Herdr で再現することが目的ではない。現在の tmux 運用で便利だった作業体験を、Herdr の思想と機能に寄せて移植する。

特に重要なのは、複数のプロジェクトディレクトリを同時に開き、一覧で把握し、必要な workspace へすばやく移動し、戻ってもその workspace 内の作業状態が残っていること。

## 現行 tmux 運用で維持したい体験

- 1 つの tmux session の中に、複数のフォルダを window として開いている。
- 下部の window 一覧で、今開いているフォルダ群を横断的に見られる。
- window は 1 から 15 のように番号で並び、必要なフォルダへすぐジャンプできる。
- 各フォルダ/window の中では、4 ペイン程度に分割して作業している。
- あるフォルダで pane 状態を維持したまま、別フォルダへ移動できる。
- 別フォルダで作業した後、元のフォルダへ戻っても pane の配置や作業文脈が残っている。
- 「今どの workspace / フォルダを全部開いているか」が常に分かることが重要。
- 手動で `cd` してから別コマンドを打つような運用は、現行 tmux 体験よりかなり不便なので避けたい。

## Herdr 移行後の workspace 要件

- tmux window に相当する単位は、Herdr workspace として扱う。
- 1 プロジェクトディレクトリにつき 1 workspace を基本にする。
- 複数 workspace を一覧できる UI が必要。
- Herdr に tmux の下部横並び window bar と同等の UI がない場合は、Herdr の sidebar / workspace picker / indexed workspace switching を使う。
- CLI だけでなく、通常操作として自然に一覧・移動できることを重視する。
- `herdrw` のような helper がある場合も、用途は「現在開いている workspace の一覧確認」「workspace を開く/フォーカスする」「履歴を保存/復元する」に絞る。
- 既存の `herdrp`, `herdrw`, `herdr-layout-dev`, `herdr-layout-dev-wide` は誤った要件のもとに作ったものなので、互換性維持は不要。
- 破壊的変更、削除、置換、改名は許容する。

## 再起動後の復元要件

- PC 再起動後に、pane 内の実行中プロセスまで維持する必要はない。
- ただし、前回どの workspace / ディレクトリを開いていたかは復元できる必要がある。
- Herdr 公式 docs では、server restart 後に workspaces, tabs, panes, cwd, layout, focus の session shape は snapshot restore されると説明されている。
- running shells, dev servers, tests, arbitrary processes は復元されない前提でよい。
- Herdr の native snapshot restore を主系にする。
- それとは別に、workspace の種類だけを明示的に保存する history を用意する価値がある。
- 履歴に保存する対象は、最低限 `session`, `saved_at`, workspace label, canonical path, active workspace path。
- 欠損したディレクトリは復元時にスキップし、勝手に `$HOME` などへ置き換えない。
- pane history replay は secret や token を含む可能性があるため、必要性が明確になるまで有効化しない。
- `resume_agents_on_restore` はユーザー要件ではないため、既存の Claude/Codex 連携を壊さないよう、勝手に無効化しない。

## Ghostty / zsh 起動要件

- 現在は Ghostty 起動時に `.zshrc` で tmux を自動 attach/new している。
- 移行後は Ghostty 起動時に Herdr の共有 session へ入る体験にしたい。
- ただし Herdr 内 pane の shell にも Ghostty 系 env が継承され得るため、Ghostty 判定だけで Herdr を起動してはいけない。
- Ghostty 側から明示的な top-level marker を渡す必要がある。
- 例: `HERDR_AUTO_ENTRY=1` を Ghostty の entrypoint で付与する。
- Herdr 起動前に `HERDR_AUTO_ENTRY` は unset し、子 shell へ残さない。
- `.zshrc` は `HERDR_AUTO_ENTRY=1` かつ guard をすべて通った場合だけ Herdr に入る。
- Conductor, Codex, SSH, tmux, 既存 Herdr pane では自動起動しない。

### 自動起動 guard

最低限、以下のいずれかがある場合は Herdr 自動起動しない。

- `HERDR_ENV`
- `HERDR_SESSION`
- `HERDR_SOCKET_PATH`
- `TMUX`
- `DISABLE_AUTO_HERDR`
- `CONDUCTOR_WORKSPACE_PATH`
- `CONDUCTOR_ROOT_PATH`
- `CODEX_THREAD_ID`
- `CODEX_CI`
- `CODEX_HOME`
- `CODEX_SANDBOX_NETWORK_DISABLED`
- `SSH_CONNECTION`
- `SSH_TTY`

Herdr 内 shell では、実測として `HERDR_ENV`, `HERDR_SESSION`, `HERDR_SOCKET_PATH`, `HERDR_WORKSPACE_ID`, `HERDR_TAB_ID`, `HERDR_PANE_ID` が立っていた。

## tmux ショートカット互換要件

移行時は workspace 体験だけでなく、現在の tmux ショートカット操作感も棚卸しして Herdr へ割り当てる。

### 必ず対応する操作

- prefix は tmux と同じ `ctrl+b` を基本にする。
- `prefix + z`: focused pane の zoom / fullscreen。
- `prefix + h/j/k/l`: pane focus 移動。
- `prefix + H/J/K/L`: pane resize 相当。Herdr の resize mode などに寄せる。
- `prefix + "`: current cwd で vertical split 相当。
- `prefix + %`: current cwd で horizontal split 相当。
- `prefix + c`: current cwd で新しい作業単位を作る。Herdr では tab か workspace のどちらが自然か設計で決める。
- `prefix + p`: previous tab/workspace 相当。
- `prefix + 1..9`: tab switching。
- workspace switching 用に `prefix + shift + 1..9` などの indexed binding を検討する。
- `prefix + w`: workspace picker。
- `prefix + b`: sidebar toggle。
- `prefix + q`: detach。

### popup 系ショートカット

tmux では `display-popup` で以下を使っている。

- `prefix + P`: popup shell。
- `prefix + g`: lazygit。
- `prefix + s`: lazysql。
- `prefix + v`: nvim。
- `prefix + t`: top。
- `prefix + f`: fzf で選んだファイルを nvim。
- `prefix + C`: tmux profile。

Herdr では `[[keys.command]]` の temporary pane などで代替できる可能性がある。popup と完全に同じ見た目でなくてもよいが、「現在の workspace / pane cwd から素早く補助ツールを開く」体験は維持したい。

### 要検討または代替が必要な操作

- tmux copy-mode vi keymap と `pbcopy` 連携。
- mouse drag copy。
- right-click custom pane menu。
- focus-follows-mouse。
- image passthrough。
- tmux statusline の色・時刻表示。
- tmux hook による window state auto-save/restore。
- `tmux-dev-layout` / `tmux-dev-layout2` 相当の固定 layout helper。

これらは Herdr 側に同等機能があるかを確認し、ない場合は無理に tmux 互換再現しない。ただし「なぜ落とすのか」「代替操作は何か」は明示する。

## Herdr config 要件

- dotfiles 管理の Herdr config を用意する。
- `link.sh` で `~/.config/herdr/config.toml` へ symlink できるようにする。
- `onboarding = false` は維持してよい。
- `[ui] agent_panel_sort = "spaces"` は既存設定として維持してよい。
- sidebar を workspace 一覧の主 UI として使いやすい幅にする。
- `workspace_picker`, `toggle_sidebar`, `switch_workspace`, `previous_workspace`, `next_workspace`, `zoom`, `focus_pane_*`, `split_*`, `resize_mode` を明示設定する。
- `pane_history` は false のままにする。
- `resume_agents_on_restore` は明示変更しない。

## helper command 要件

helper は「tmux の代替 UI を独自実装する」ものではなく、Herdr の workspace 運用を補助するものにする。

想定する役割:

- `herdrp`: Ghostty / zsh から安全に Herdr shared session へ入る entrypoint。
- `herdrw list`: 現在の Herdr workspace 一覧を表示する。
- `herdrw open [path]`: path に対応する workspace を focus、なければ create。
- `herdrw save`: workspace history を保存する。
- `herdrw restore`: workspace history から workspace set を復元する。

helper は Herdr server や user session を不用意に stop/delete しない。

## レビュー要件

- 実装計画を提示する前に Codex review を通す。
- Fable review を使う場合、Herdr の `--help`, `--default-config`, `status`, `workspace list`, `api snapshot` などの read-only introspection を実行できるようにする。
- Fable review は whitelist で個別コマンド追加していく方式ではなく、read-only review のために必要な local CLI introspection を許す blacklist 方式が望ましい。
- ただし destructive command, install, deploy, external review launch, mutation は deny する。

## 非目標

- tmux の実装を Herdr 上に完全再現すること。
- tmux bottom statusline と完全同一の UI を作ること。
- PC 再起動後にプロセスを復元すること。
- pane screen history をデフォルトで保存すること。
- 誤った初期要件で作った helper との互換性を維持すること。

## 未決事項

- Herdr で tmux の下部横並び window 一覧に最も近い常用 UI は sidebar / picker / indexed switch のどれを主にするか。
- `prefix + c` を Herdr tab 作成にするか、workspace 作成にするか。
- `prefix + "` / `prefix + %` のキー表記が Herdr config でどの名前になるか。
- `prefix + H/J/K/L` を直接 resize にできるか、resize mode 経由にするか。
- popup 系を temporary pane で十分とするか、別の Herdr 機能を使うか。
- `ghq + peco` の選択後は `cd` ではなく `herdrw open` へつなぐべきか。
- workspace history の自動保存タイミングを `herdrw open` のみにするか、detach 時にも行うか。
