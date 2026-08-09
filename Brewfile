# dotfiles 自身が前提にする基盤ツールのみ。
# アプリ・言語ツールは新環境で必要になった時に都度 brew install する方針
# (使わなくなったものを再インストールする無駄を避ける)。

# shell 起動 (common.sh / .zshrc) が直接参照
brew "starship"
brew "sheldon"
brew "direnv"
brew "asdf"
brew "peco"
brew "ghq"

# エディタ・マルチプレクサ (設定ファイルが repo にある)
brew "neovim"
brew "tmux"

# githooks/pre-commit (gitleaks) と make runtimes が前提
brew "aquaproj/aqua/aqua"

# CI / make lint と同じ検査をローカルでも
brew "shellcheck"
