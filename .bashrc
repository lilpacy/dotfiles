# ローカルのパス優先度を変更
export PATH=/usr/local/bin:$PATH
export PATH=/opt/homebrew/bin:$PATH

# エイリアス
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

#eval "$(rbenv init -)"
#export PATH="$PATH:$HOME/.rbenv/bin"

# openssl
export PATH="/opt/homebrew/opt/openssl@3/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/openssl@3/lib"
export CPPFLAGS="-I/opt/homebrew/opt/openssl@3/include"
export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@3/lib/pkgconfig"

# gcloud sdk
#source /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc
#source /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc

# boostnote
alias backup-bs="/bin/bash -l -c 'cd /Users/lilpacy/Library/CloudStorage/GoogleDrive-revivedtomorrow@gmail.com/My\ Drive/Boostnote && sh -x backup.sh'"
alias backup-ob="/bin/bash -l -c 'cd /Users/lilpacy/Library/CloudStorage/GoogleDrive-revivedtomorrow@gmail.com/My\ Drive/Obsidian && sh -x backup.sh'"
alias backup-al="/bin/bash -l -c 'cd ~/Library/Application\ Support/Alfred/ && sh -x backup.sh'"

# elixir
. /opt/homebrew/opt/asdf/libexec/asdf.sh

# Language
export LANG='ja_JP.UTF-8'
export LC_ALL='ja_JP.UTF-8'
export LC_MESSAGES='ja_JP.UTF-8'

# others
#export LDFLAGS="-L/opt/homebrew/opt/bison/lib"

# asdf
. /opt/homebrew/opt/asdf/libexec/asdf.sh

# starship
eval "$(starship init bash)"

# aqua
export PATH="${AQUA_ROOT_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/aquaproj-aqua}/bin:$PATH"

# pnpm
export PNPM_HOME="/Users/lilpacy/Library/pnpm"
case ":$PATH:" in
*":$PNPM_HOME:"*) ;;
*) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
