# tmux
	export TERM="xterm-256color"
	#複数の仮想端末で履歴を共有(同じコマンドは残さない)
	#https://qiita.com/piroor/items/7c9380e408d07fd83bfc
	function share_history {
	  history -a
	  # ここから追記
	  tac ~/.bash_history | awk '!a[$0]++' | tac > ~/.bash_history.tmp
	  mv ~/.bash_history{.tmp,}
	  # ここまで追記
	  history -c
	  history -r
	}
	PROMPT_COMMAND='share_history'

# POWERLEVEL9K Configuration
	POWERLEVEL9K_MODE='nerdfont-complete'
	ZSH_THEME="powerlevel9k/powerlevel9k"

# Customise the Powerlevel9k prompts
	POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
	  dir
	  custom_javascript 
	  vcs
	  newline
	  status
	)
	POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=()
	POWERLEVEL9K_PROMPT_ADD_NEWLINE=true

	HOMEBREW_FOLDER="/usr/local/share"
	fpath=(/usr/local/share/zsh-completions $fpath)
	autoload -U compinit
	ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor)

	# 補完候補ハイライト
	zstyle ':completion:*:default' menu select=2
	alias ls='ls -G'
	alias ll='ls -lG'
	alias la='ls -alG'

	# 'cd' なしで移動する
	setopt auto_cd
	setopt auto_pushd

	# 移動した後は 'ls' する
	function chpwd() { ls -aF }

	# 補完関数の表示を強化する
	zstyle ':completion:*' verbose yes
	zstyle ':completion:*' completer _expand _complete _match _prefix _approximate _list _history
	zstyle ':completion:*:messages' format '%F{YELLOW}%d'$DEFAULT
	zstyle ':completion:*:warnings' format '%F{RED}No matches for:''%F{YELLOW} %d'$DEFAULT
	zstyle ':completion:*:descriptions' format '%F{YELLOW}completing %B%d%b'$DEFAULT
	zstyle ':completion:*:options' description 'yes'
	zstyle ':completion:*:descriptions' format '%F{yellow}Completing %B%d%b%f'$DEFAULT

	# マッチ種別を別々に表示
	zstyle ':completion:*' group-name ''

	# 名前で色を付けるようにする
	autoload colors
	colors

	# LS_COLORSを設定しておく
	export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'

	# ファイル補完候補に色を付ける
	zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# change color everytime new tab is open
	# osascript ~/Scripts/RandomColorTerminal.scpt

# Source Prezto.
	if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
	  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
	fi

# path to original commands
	PATH="$HOME/bin:$PATH"

# history settings

	function history-all { history -E 1 }

	# history search
	bindkey '^P' history-beginning-search-backward
	bindkey '^N' history-beginning-search-forward

	# 履歴ファイルの保存先
	export HISTFILE=${HOME}/.zsh_history
	
	# メモリに保存される履歴の件数
	export HISTSIZE=1000
	
	# 履歴ファイルに保存される履歴の件数
	export SAVEHIST=100000
	
	# 重複を記録しない
	setopt hist_ignore_dups
	
	# 開始と終了を記録
	setopt EXTENDED_HISTORY
	setopt share_history

	# ヒストリに追加されるコマンド行が古いものと同じなら古いものを削除
	setopt hist_ignore_all_dups
	
	# スペースで始まるコマンド行はヒストリリストから削除
	setopt hist_ignore_space
	
	# ヒストリを呼び出してから実行する間に一旦編集可能
	setopt hist_verify
	
	# 余分な空白は詰めて記録
	setopt hist_reduce_blanks  
	
	# 古いコマンドと同じものは無視 
	setopt hist_save_no_dups
	
	# historyコマンドは履歴に登録しない
	setopt hist_no_store
	
	# 補完時にヒストリを自動的に展開         
	setopt hist_expand
	
	# 履歴をインクリメンタルに追加
	setopt inc_append_history
	
	# インクリメンタルからの検索
	bindkey "^R" history-incremental-search-backward
	bindkey "^S" history-incremental-search-forward

# suggestionの強化
	source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

# rbenv設定
	export PATH="~/.rbenv/shims:$PATH"
	eval "$(rbenv init -)"

# pynev設定
	export PYENV_ROOT="$HOME/.pyenv"
	export PATH="$PYENV_ROOT/bin:$PATH"
	eval "$(pyenv init -)"

# node設定

	#export NODEBREW_HOME="$HOME/.nodebrew/current"
	#export PATH="$PATH:$NODEBREW_HOME/bin"
	eval "$(nodenv init -)"

# sbt
	export PATH="~/.sbtenv/shims:$PATH"
	eval "$(sbtenv init -)"

# scala
	export PATH="$HOME/.scalaenv/shims:$PATH"
	eval "$(scalaenv init -)"

# 楽天API
	export RAKUTEN_APP_ID='1080527303532048143'

# YahooAPI
	export YAHOO_APP_ID='dj00aiZpPVBhV3ZuVG1DbEhKVSZzPWNvbnN1bWVyc2VjcmV0Jng9ODE-'

# mysql
	export PATH="/usr/local/opt/mysql@5.6/bin:$PATH"
	alias mr="mysql -u root"

# imagemagick
	export PKG_CONFIG_PATH=/usr/local/opt/imagemagick@6/lib/pkgconfig

# adapt vim to 256 colors
	TERM=xterm-256color

# gem
	#alias bundle="bundle _2.0.0_"

# shell back color
	alias color="osascript ~/Scripts/RandomColorTerminal.scpt"

# less with color
	export LESS=' -R '
	export LESSOPEN='| src-hilite-lesspipe.sh %s'

# Git
	alias gs='git status'
	alias gb='git branch'
	alias gd='git diff'
	alias gl='git log --graph'
	alias gll='git log --graph --oneline'
	alias ga='git add'
	alias gr='git reset HEAD'
	alias gco='git commit -m'
	alias gam='git commit --amend -m'
	alias gck='git checkout'
	alias gpf='git push --force-with-lease'

# Ruby
	alias be="bundle exec"
	alias rs="bundle exec rails s"
	alias rr="bundle exec rake routes"
	alias rc="bundle exec rails c"

# direnv configuration
	export EDITOR=vim
	export VISUAL=vim
	eval "$(direnv hook zsh)"

# jenv
	export PATH="$HONE/.jenv/bin:$PATH"
	eval "$(jenv init -)"

# yarn
	alias local-web-server="./node_modules/.bin/ws --spa index.html"

# watch
	alias watch="~/.mywatch.sh"

# google-cloud-sdk
	export GCLOUD_SDK="/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk"
	export PATH="$PATH:$GCLOUD_SDK/bin"
	export APPENGINE_SDK="$GCLOUD_SDK/platform/google_appengine"
	export PATH="$PATH:$APPENGINE_SDK"

# go config
	export GOPATH="$HOME/workspace/go"
	export GOENV_ROOT="$HOME/.goenv"
	export PATH="$GOENV_ROOT/shims:$PATH"
	export PATH="$PATH:$GOPATH/bin"
	export PORT=8080
	eval "$(goenv init -)"

# google drive
	alias cd-drive="/Users/lilpacy/Google\ Drive\ File\ Stream"
	alias cd-bstnt="/Users/lilpacy/Google\ Drive\ File\ Stream/My\ Drive/Boostnote"

# just shortcut
	alias cd-ws="cd ~/workspace"
	alias cd-atcoder="~/workspace/typescript/atcoder"
	alias cd-blog="~/workspace/elm/elm-spa-minimum"

# mpsyt
	alias ytb="mpsyt"

# broot
	source /Users/lilpacy/Library/Preferences/org.dystroy.broot/launcher/bash/br

# obs
	alias obs="/Applications/OBS.app/Contents/MacOS/OBS"

# my functions
	function mkdircd () { mkdir -p $1; cd $_ }

# prefer local binary
	export PATH="/usr/local/bin:$PATH"
