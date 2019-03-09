#
# Executes commands at the start of an interactive session.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# change color everytime new tab is open
osascript ~/Scripts/RandomColorTerminal.scpt

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# rbenv設定
export PATH="~/.rbenv/shims:/usr/local/bin:$PATH"
eval "$(rbenv init -)"

# pynev設定
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# sbt
export PATH="$HOME/.sbtenv/shims:$PATH"
eval "$(sbtenv init -)"

# scala
export PATH="$HOME/.scalaenv/shims:$PATH"
eval "$(scalaenv init -)"

# babel-cli
export PATH="$PATH:/Users/lilpacy/node_modules/.bin"

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

# Git
alias gs="git status"
alias gd="git diff"
alias gl="git log --graph"
alias gb="git branch"
alias gck="git checkout"
alias gco="git commit"
alias ga="git add"

# Rails
alias be="bundle exec"
alias rs="bundle exec rails s"
alias rr="bundle exec rake routes"
alias rc="bundle exec rails c"

# direnv configuration
export EDITOR=vim
eval "$(direnv hook zsh)"

export PATH="$HONE/.jenv/bin:$PATH"
eval "$(jenv init -)"
