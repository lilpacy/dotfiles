# change path priority to local
	export PATH=/usr/local/bin:$PATH
	export PATH=/opt/homebrew/bin:$PATH

# alias
	alias ll='ls -lh'
	alias la='ls -lah'
	alias hh='hardhat'
	alias python='python3'

# golang
	# go1.16からのgo install/getについて
	# https://qiita.com/eihigh/items/9fe52804610a8c4b7e41

	# go1.16からのgomodulesについて
	# https://zenn.dev/tennashi/articles/3b87a8d924bc9c43573e
	# 1.11導入のgomodulesは1.16からはデフォルトでon
	# だが別バージョンでの開発のために一応書いておく
	# intellijでgo modulesをonにするのも忘れずに。
	# onにすることで$GOPATH/srcの外でも開発ができる
	export GO111MODULE=on

	# 『改訂2版 みんなのGO言語』
	# go1.16からはgomodulesがデフォルトonになりGOPATHからは解放されているが
	# 他のバージョンの開発のために一応設定しておく
	export GOPATH=$(go env GOPATH)

	# go installで入れた実行ファイルにパスを通す
	# ~/binの方はgo env -w GOBIN=~/binで設定している
	# go1.13からgoenv -wでgoの設定値を変更可能に
	# けどgo env -wで設定したものより環境変数が優先されるらしい
	# 値はgo env HOGEで確認できるが実体はgo env GOENVにある
	# https://text.baldanders.info/golang/go-env/
	export PATH=$PATH:~/bin
	export PATH=$PATH:$GOPATH/bin

# git
	alias gs='git status'
	alias gb='git branch'
	alias gd='git diff'
	alias gl='git log --graph'
	alias gll='git log --graph --oneline'
	alias ga='git add'
	alias gco='git commit -m'
	alias gam='git commit --amend -m'
	alias gck='git checkout'
	alias gpf='git push --force-with-lease'
	alias gpp='git pull --prune'

# tmux
	if [[ ! "$TERM" =~ "screen" ]]; then
		tmux attach -t default || tmux new -s default
	fi

# direnv
	eval "$(direnv hook zsh)"

# rbenv
	#eval "$(rbenv init -)"
	#export PATH="$PATH:$HOME/.rbenv/bin"

# openssl
	export PATH="/opt/homebrew/opt/openssl@3/bin:$PATH"
	export LDFLAGS="-L/opt/homebrew/opt/openssl@3/lib"
	export CPPFLAGS="-I/opt/homebrew/opt/openssl@3/include"
	export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@3/lib/pkgconfig"

# gcloud sdk
	#source /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc
	#source /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc

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

# bookmark
	# https://threkk.medium.com/how-to-use-bookmarks-in-bash-zsh-6b8074e40774
	if [ -d "$HOME/.bookmarks" ]; then
	    export CDPATH=".:$HOME/.bookmarks:/"
	    alias goto="cd -P"
	fi

# ghq x peco
	bindkey '^]' peco-src
	function peco-src(){
		local src=$(ghq list --full-path|peco --query "$LBUFFER")
		if [ -n "$src" ]; then
			BUFFER="cd $src"
			zle accept-line
		fi
			zle -R -c
	}
	zle -N peco-src

# boostnote
	alias backup-bs="/bin/bash -l -c 'cd /Users/lilpacy/Library/CloudStorage/GoogleDrive-revivedtomorrow@gmail.com/My\ Drive/Boostnote && sh -x backup.sh'"
	alias backup-ob="/bin/bash -l -c 'cd /Users/lilpacy/go/src/github.com/lilpacy/obsidian && sh -x backup.sh'"
	alias backup-al="/bin/bash -l -c 'cd ~/Library/Application\ Support/Alfred/ && sh -x backup.sh'"

# elixir
	. /opt/homebrew/opt/asdf/libexec/asdf.sh

# Language
	export LANG='ja_JP.UTF-8'
	export LC_ALL='ja_JP.UTF-8'
	export LC_MESSAGES='ja_JP.UTF-8'

# aws
	export AWS_REGION=ap-northeast-1
	export AWS_PROFILE=cryptogames-local-dev

# others
	#export LDFLAGS="-L/opt/homebrew/opt/bison/lib"

# asdf
	. /opt/homebrew/opt/asdf/libexec/asdf.sh

# cairo
	export PATH="$PATH:/Users/lilpacy/.protostar/dist/protostar"
	export PATH="$PATH:$HOME/.local/bin"

# walk
	function lk {
		  cd "$(walk "$@")"
	}
	export EDITOR=vim


# bun completions
	[ -s "/Users/lilpacy/.bun/_bun" ] && source "/Users/lilpacy/.bun/_bun"

# bun
	export BUN_INSTALL="$HOME/.bun"
	export PATH="$BUN_INSTALL/bin:$PATH"

# starship
	eval "$(starship init zsh)"

# aqua
	export PATH="${AQUA_ROOT_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/aquaproj-aqua}/bin:$PATH"

# pnpm
	export PNPM_HOME="/Users/lilpacy/Library/pnpm"
	case ":$PATH:" in
	  *":$PNPM_HOME:"*) ;;
	  *) export PATH="$PNPM_HOME:$PATH" ;;
	esac
# pnpm end

# sheldon
	eval "$(sheldon source)"

	# fshow - git commit browser
	fshow() {
	  git log --graph --color=always \
	      --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
	  fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
	      --bind "ctrl-m:execute:
	                (grep -o '[a-f0-9]\{7\}' | head -1 |
	                xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
	                {}
					FZF-EOF"
	}
