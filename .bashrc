source ${BASH_SOURCE[0]%/*}/dotfiles/common.sh

# starship
eval "$(starship init bash)"

# fzf
eval "$(fzf --bash)"
