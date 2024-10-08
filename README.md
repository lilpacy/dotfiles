# dotfiles

## setup

```sh
brew install asdf

asdf plugin add nodejs
asdf install nodejs 20.12.2
asdf global nodejs 20.12.2

# aquaなどbrewのパッケージでarm64で動かないものがあるのでrosettaを入れる
softwareupdate --install-rosetta
brew install aquaproj/aqua/aqua

npm i
aqua i

chmod 700 link.sh
./link.sh
```

## homebrew

backup

```sh
brew list --formula > homebrew/formula
brew list --cask > homebrew/cask
```

install

```sh
cat homebrew/*|xargs brew install
```
