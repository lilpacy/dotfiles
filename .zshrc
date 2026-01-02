source ${ZDOTDIR:-$HOME}/dotfiles/common.sh

# tmux
	if [[ -z "$TMUX" ]] && [[ ! "$TERM" =~ "screen" ]]; then
		tmux attach -t default || tmux new -s default
	fi

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
        BUFFER="cd $src"
        zle accept-line
    fi
    zle -R -c
}
zle -N peco-src

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
