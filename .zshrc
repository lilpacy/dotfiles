source ${ZDOTDIR:-$HOME}/dotfiles/common.sh

# Ghostty top-level shells enter the shared Herdr session only when explicitly
# marked by Ghostty config. Herdr panes, tmux, SSH, Codex, and Conductor must
# remain normal shells.
function should_auto_enter_herdr() {
    [[ "${HERDR_AUTO_ENTRY:-}" == "1" ]] || return 1
    [[ -z "${HERDR_ENV:-}" ]] || return 1
    [[ -z "${HERDR_SESSION:-}" ]] || return 1
    [[ -z "${HERDR_SOCKET_PATH:-}" ]] || return 1
    [[ -z "${TMUX:-}" ]] || return 1
    [[ -z "${DISABLE_AUTO_HERDR:-}" ]] || return 1
    [[ -z "${CONDUCTOR_WORKSPACE_PATH:-}" ]] || return 1
    [[ -z "${CONDUCTOR_ROOT_PATH:-}" ]] || return 1
    [[ -z "${CODEX_THREAD_ID:-}" ]] || return 1
    [[ -z "${CODEX_CI:-}" ]] || return 1
    [[ -z "${CODEX_HOME:-}" ]] || return 1
    [[ -z "${CODEX_SANDBOX_NETWORK_DISABLED:-}" ]] || return 1
    [[ -z "${SSH_CONNECTION:-}" ]] || return 1
    [[ -z "${SSH_TTY:-}" ]] || return 1
    command -v herdrp >/dev/null 2>&1 || return 1
}

if should_auto_enter_herdr; then
    unset HERDR_AUTO_ENTRY
    exec herdrp
fi
unset HERDR_AUTO_ENTRY

# direnv
eval "$(direnv hook zsh)"


# zsh history
	# https://qiita.com/syui/items/c1a1567b2b76051f50c4
	# 重複を記録しない
	setopt hist_ignore_all_dups
	# 開始と終了を記録
	setopt EXTENDED_HISTORY
	# 全履歴一覧表示
	function history-all { history -E 1 }
	# ヒストリーの共有
	setopt share_history
	# 補完時にヒストリを自動的に展開         
	setopt hist_expand
	# ヒストリーファイルの設定
	HISTFILE=$HOME/.zsh_history
	# メモリに保存される履歴の件数
	HISTSIZE=100000
	# 履歴ファイルに保存される履歴の件数
	SAVEHIST=100000
	# ヒストリーの共有
	setopt share_history
	# 重複を記録しない
	setopt hist_ignore_all_dups
	# ディレクトリスタックへの自動追加
	setopt auto_pushd
	# 自動的にcd
	setopt auto_cd
	# 補完システムの初期化
	autoload -Uz compinit
	compinit
	# reverse-i-search
	bindkey '^R' history-incremental-search-backward

# peco wrapper for tmux-256color compatibility
function peco() {
    env TERM=screen-256color command peco "$@"
}

# ghq x peco
bindkey '^]' peco-src
function peco-src() {
    local src=$(ghq list --full-path | peco --query "$LBUFFER")
    if [ -n "$src" ]; then
        if [[ -n "${HERDR_SESSION:-}" || -n "${HERDR_SOCKET_PATH:-}" ]]; then
            BUFFER="herdrw open ${(q)src}"
        else
            BUFFER="cd ${(q)src}"
        fi
        zle accept-line
    fi
    zle -R -c
}
zle -N peco-src

# git worktree x peco
gwt() {
  local dir
  dir=$(git worktree list | peco | awk '{print $1}')
  [ -n "$dir" ] && cd "$dir"
}

# bun completions
[ -s "/Users/lilpacy/.bun/_bun" ] && source "/Users/lilpacy/.bun/_bun"

# starship
eval "$(starship init zsh)"

# sheldon
eval "$(sheldon source)"

# neofetchが存在する場合は実行
if (( $+commands[neofetch] )); then
    neofetch
fi

export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
export CPPFLAGS="-I/opt/homebrew/opt/openjdk/include"
export JAVA_HOME=$(/usr/libexec/java_home)
export PATH=$JAVA_HOME/bin:$PATH
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/build-tools/latest

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/lilpacy/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/lilpacy/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/lilpacy/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/lilpacy/google-cloud-sdk/completion.zsh.inc'; fi
