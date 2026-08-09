# dotfiles

## setup

```sh
# aquaなどbrewのパッケージでarm64で動かないものがあるのでrosettaを入れる
softwareupdate --install-rosetta

make install   # brew bundle -> asdf/aqua runtimes -> link.sh
```

個別に実行する場合は `make brew` / `make runtimes` / `make link`。

## homebrew

backup

```sh
brew bundle dump --file=Brewfile --force --no-vscode
```

install

```sh
brew bundle --file=Brewfile
```
