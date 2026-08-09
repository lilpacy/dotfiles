# dotfiles

## setup

```sh
# aquaなどbrewのパッケージでarm64で動かないものがあるのでrosettaを入れる
softwareupdate --install-rosetta

make install   # brew bundle -> asdf/aqua runtimes -> link.sh
```

個別に実行する場合は `make brew` / `make runtimes` / `make link`。

## homebrew

`Brewfile` は dotfiles 自身が前提にする基盤ツールのみを宣言する。
アプリ・言語ツールは新環境で必要になった時に都度 `brew install` する
(使わなくなったものを再インストールする無駄を避ける方針)。

```sh
brew bundle --file=Brewfile
```
