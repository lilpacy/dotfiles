ln -sf ~/dotfiles/.vimrc ~/.vimrc
ln -sf ~/dotfiles/.zshrc ~/.zshrc
ln -sf ~/dotfiles/.tmux.conf ~/.tmux.conf
ln -sf ~/dotfiles/starship.toml ~/.config/starship.toml
ln -sf ~/dotfiles/sheldon/plugins.toml ~/.config/sheldon/plugins.toml

chmod 700 ~/dotfiles/shell/task_cal
sudo ln -sf ~/dotfiles/shell/task_cal /usr/local/bin/task_cal