# emacs keybind
set -o emacs

# change path priority to local
export PATH=/usr/local/bin:$PATH
export PATH=/opt/homebrew/bin:$PATH

# dotfiles/bin
export PATH="$HOME/dotfiles/bin:$PATH"

# alias
alias ll='ls -lh'
alias la='ls -lah'
alias hh='hardhat'
alias obsidian='command obsidian 2>&1 | grep -v "FATAL:electron/shell/app/electron_main_delegate_mac.mm"'
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
mkdir -p ~/go/bin ~/go/src ~/go/pkg
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

# bookmark
# https://threkk.medium.com/how-to-use-bookmarks-in-bash-zsh-6b8074e40774
if [ -d "$HOME/.bookmarks" ]; then
    export CDPATH=".:$HOME/.bookmarks:/"
    alias goto="cd -P"
fi

# backups
alias backup-bs="/bin/bash -l -c 'cd /Users/lilpacy/Library/CloudStorage/GoogleDrive-revivedtomorrow@gmail.com/My\ Drive/Boostnote && sh -x backup.sh'"
alias backup-ob="/bin/bash -l -c 'cd /Users/lilpacy/go/src/github.com/lilpacy/obsidian && sh -x backup.sh'"
alias backup-al="/bin/bash -l -c 'cd /Users/lilpacy/go/src/github.com/lilpacy/alfred-preferences/ && sh -x backup.sh'"

# elixir
. /opt/homebrew/opt/asdf/libexec/asdf.sh

# Language
export LANG='ja_JP.UTF-8'
export LC_ALL='ja_JP.UTF-8'
export LC_MESSAGES='ja_JP.UTF-8'

# aws
export AWS_REGION=ap-northeast-1
export AWS_PROFILE=pacy-operator

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

# vim
export EDITOR=vim
alias vi=nvim
alias vim=nvim

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# aqua
export PATH="${AQUA_ROOT_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/aquaproj-aqua}/bin:$PATH"

# pnpm
export PNPM_HOME="/Users/lilpacy/Library/pnpm"
case ":$PATH:" in
*":$PNPM_HOME:"*) ;;
*) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

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

pbedit() {
    local _t=$(mktemp)
    chmod 600 "$_t"

    pbpaste >"$_t"
    ${EDITOR:-vi} "$_t"
    pbcopy <"$_t"

    rm -f "$_t"
}

# https://zenn.dev/s_ha_3000/articles/71d10761889ac7
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/anaconda3/bin/conda' 'shell.zsh' 'hook' 2>/dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/opt/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/opt/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# yabai
alias yabai-start='yabai --start-service'
alias yabai-stop='yabai --stop-service'
alias yabai-restart='yabai --restart-service'

# postgresql
export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/postgresql@15/lib"
export CPPFLAGS="-I/opt/homebrew/opt/postgresql@15/include"
export PKG_CONFIG_PATH="/opt/homebrew/opt/postgresql@15/lib/pkgconfig"

# windsurf
export PATH="/Users/lilpacy/.codeium/windsurf/bin:$PATH"

# kiro
[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path bash)"

# llvm(for scan-build)
export PATH="/opt/homebrew/opt/llvm/bin:$PATH"

# claude code
export CLAUDE_CODE_USE_BEDROCK=1
export ANTHROPIC_MODEL='global.anthropic.claude-sonnet-4-5-20250929-v1:0'
export CLAUDE_CODE_MAX_OUTPUT_TOKENS=4096
export MAX_THINKING_TOKENS=1024
alias claude='claude --dangerously-skip-permissions'
alias claude-mem='bun "/Users/lilpacy/.claude/plugins/marketplaces/thedotmack/plugin/scripts/worker-service.cjs"'

# codex
codex() {
    command codex -m gpt-5.4 \
      -c model_context_window=1000000 \
      -c model_auto_compact_token_limit=955000 \
      --enable fast_mode \
      "$@"
}

# alias opus/sonnet の実体を Bedrock inference profile に割り当て、/model {opus,sonnet}で切り替え
export ANTHROPIC_DEFAULT_OPUS_MODEL='global.anthropic.claude-opus-4-5-20251101-v1:0'
export ANTHROPIC_DEFAULT_SONNET_MODEL='jp.anthropic.claude-sonnet-4-5-20250929-v1:0'

