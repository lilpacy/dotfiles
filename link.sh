mkdir -p ~/.config
mkdir -p ~/.config/sheldon/
mkdir -p ~/.config/karabiner/
sudo mkdir -p /usr/local/bin/

ln -sf ~/dotfiles/.vimrc ~/.vimrc
ln -sf ~/dotfiles/.zshrc ~/.zshrc
ln -sf ~/dotfiles/.bashrc ~/.bashrc
ln -sf ~/dotfiles/.tmux.conf ~/.tmux.conf
ln -sf ~/dotfiles/starship.toml ~/.config/starship.toml
ln -sf ~/dotfiles/sheldon/plugins.toml ~/.config/sheldon/plugins.toml
ln -sf ~/dotfiles/.yabairc ~/.yabairc
ln -sf ~/dotfiles/.skhdrc ~/.skhdrc
ln -sf ~/dotfiles/karabiner.json ~/.config/karabiner/karabiner.json
ln -sf ~/dotfiles/.gitconfig ~/.gitconfig
ln -sf ~/dotfiles/.alacritty.toml ~/.alacritty.toml

sudo ln -sf ~/dotfiles/shell/task_cal /usr/local/bin/task_cal
sudo ln -sf ~/dotfiles/shell/sssh /usr/local/bin/sssh
find shell | xargs -p chmod 700
