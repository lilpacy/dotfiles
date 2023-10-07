# dotfiles

## setup

```sh
npm i
aqua i
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
