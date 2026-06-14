# Local Dictation Architecture

## 目的

`dictation` はローカル音声入力機能そのものを所有する。Karabiner、Hammerspoon、Homebrew、dotfiles のリンク処理はそれぞれ別の責務を持つため、`dictation/` 配下へ無理に集約しない。

## フォルダ構成

```text
dictation/
  bin/
    local-dictation
  scripts/
    config.sh
    lib.sh
    start.sh
    stop.sh
    toggle.sh
    transcribe.sh
  test/
    dictation.bats
  docs/
    architecture.md
    improve-dictation.md
    improvement-log.md
  README.md

bin/
  local-dictation

.hammerspoon/
  init.lua
  modules/
    dictation.lua

.config/karabiner/
  karabiner.json
```

## 所有権

```text
dictation/          = 音声入力機能そのもの
bin/local-dictation = dotfiles全体に公開するCLI入口
.hammerspoon/       = Hammerspoon設定
.config/karabiner/  = Karabiner設定
homebrew/           = brew管理
link.sh             = dotfilesリンク管理
Makefile            = repo全体の集約
```

## 公開入口

PATH から直接呼ばれる公開コマンドは `bin/local-dictation` だけにする。このファイルは薄い shim として `dictation/bin/local-dictation` を `exec` する。

`dictation/bin/local-dictation` は機能側のエントリポイントで、`dictation/scripts/` 配下の `toggle.sh`、`start.sh`、`stop.sh`、`transcribe.sh` に処理を委譲する。

## Hammerspoon

Hammerspoon は dictation 専用ではなく、複数用途を束ねるグローバル設定である。そのため `.hammerspoon/init.lua` へ dictation の処理を直書きせず、Hammerspoon 設定の一部として `.hammerspoon/modules/dictation.lua` に切り出す。

```lua
require("modules.dictation")
```

これは dictation を Hammerspoon 配下に漏らすのではなく、Hammerspoon の責務として「F18 を受けて公開CLIを呼ぶ連携」を持たせる整理である。

## Karabiner

Karabiner はさらにグローバル設定色が強く、`.config/karabiner/karabiner.json` が実設定の source of truth である。

dictation 配下に Karabiner ルールの原本を別途置くと、実設定との二重管理になりやすい。そのため `dictation/` には Karabiner JSON のコピーや example を置かない。README には「右 Control 単体 -> F18 の設定は Karabiner 側にある」とだけ書く。

## Makefile

root の `Makefile` は repo 全体の集約として残す。dictation 固有の lint/test 詳細は `dictation/Makefile` が持ち、root は `$(MAKE) -C dictation ...` で委譲する。
