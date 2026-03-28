mkdir -p ~/.config
mkdir -p ~/.config/sheldon/
mkdir -p ~/.config/karabiner/
mkdir -p ~/.config/git/
mkdir -p ~/.config/ghostty/
mkdir -p ~/.config/agents/
mkdir -p ~/.config/alacritty/
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
ln -sfn ~/dotfiles/claude/agents ~/.claude/agents
ln -sfn ~/dotfiles/claude/commands ~/.claude/commands
ln -sf ~/dotfiles/claude/CLAUDE.md ~/.claude/CLAUDE.md
ln -sf ~/dotfiles/AGENTS.md ~/.codex/AGENTS.md
ln -sf ~/dotfiles/.gitignore_global ~/.config/git/ignore
ln -sf ~/dotfiles/.config/lazygit/config.yml "$HOME/Library/Application Support/lazygit/config.yml"
ln -sf ~/dotfiles/.aerospace.toml ~/.aerospace.toml
ln -sf ~/dotfiles/ghostty ~/.config/ghostty/config
ln -sf ~/dotfiles/alacritty/catppuccin-frappe.toml ~/.config/alacritty/catppuccin-frappe.toml

sudo ln -sf ~/dotfiles/bin/task_cal /usr/local/bin/task_cal
sudo ln -sf ~/dotfiles/bin/sssh /usr/local/bin/sssh
sudo ln -sf ~/dotfiles/bin/tmux-dev /usr/local/bin/tmux-dev
find bin -type f | xargs chmod 755

