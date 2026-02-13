mkdir -p ~/.config
mkdir -p ~/.config/sheldon/
mkdir -p ~/.config/karabiner/
mkdir -p ~/.config/git/
mkdir -p ~/.config/ghostty/
mkdir -p "$HOME/Library/Application Support/lazygit"
sudo mkdir -p /usr/local/bin/

ln -sf ~/dotfiles/.vimrc ~/.vimrc
ln -sf ~/dotfiles/.zshrc ~/.zshrc
ln -sf ~/dotfiles/.bashrc ~/.bashrc
ln -sf ~/dotfiles/.tmux.conf ~/.tmux.conf
ln -sf ~/dotfiles/starship.toml ~/.config/starship.toml
ln -sf ~/dotfiles/sheldon/plugins.toml ~/.config/sheldon/plugins.toml
ln -sf ~/dotfiles/karabiner.json ~/.config/karabiner/karabiner.json
ln -sf ~/dotfiles/.gitconfig ~/.gitconfig
ln -sf ~/dotfiles/.alacritty.toml ~/.alacritty.toml
ln -sfn ~/dotfiles/nvim ~/.config/nvim
ln -sf ~/dotfiles/claude/settings.json ~/.claude/settings.json
ln -sfn ~/dotfiles/claude/skills ~/.claude/skills
ln -sfn ~/dotfiles/claude/commands ~/.claude/commands
ln -sf ~/dotfiles/claude/CLAUDE.md ~/.claude/CLAUDE.md
ln -sf ~/dotfiles/.gitignore_global ~/.config/git/ignore
ln -sf ~/dotfiles/.config/lazygit/config.yml "$HOME/Library/Application Support/lazygit/config.yml"
ln -sf ~/dotfiles/.aerospace.toml ~/.aerospace.toml
ln -sf ~/dotfiles/ghostty ~/.config/ghostty/config

sudo ln -sf ~/dotfiles/shell/task_cal /usr/local/bin/task_cal
sudo ln -sf ~/dotfiles/shell/sssh /usr/local/bin/sssh
sudo ln -sf ~/dotfiles/shell/tmux-dev /usr/local/bin/tmux-dev
find shell | xargs -p chmod 700

