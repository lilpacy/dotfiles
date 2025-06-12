#!/bin/bash

DESKPAD_UUID="0A9C5967-4500-41CC-B9F4-4AF6557F454E"
BUILTIN_UUID="37D8832A-2D66-02CA-B9F7-8F30A301B230"

# Deskpadの接続確認
yabai -m query --displays | grep -q "$DESKPAD_UUID"
deskpad_connected=$?

# 内蔵ディスプレイの状態確認（クラムシェルモードかどうか）
yabai -m query --displays | grep -q "$BUILTIN_UUID"
builtin_display_connected=$?

# 他のモニターの接続確認（Deskpadと内蔵ディスプレイ以外）
other_monitor_connected=0
if [ $deskpad_connected -eq 0 ] || [ $builtin_display_connected -eq 0 ]; then
    # 接続されているディスプレイの数を取得
    display_count=$(yabai -m query --displays | grep -c "uuid")
    if [ $display_count -gt 1 ]; then
        other_monitor_connected=1
    fi
fi

# [ディシジョンテーブル](https://gyazo.com/056546451b4921ce8fcb3a44015850d3.png)
if [ $deskpad_connected -eq 0 ]; then
    # Deskpadが接続されている場合
    yabai -m config layout float
elif [ $builtin_display_connected -eq 0 ] && [ $other_monitor_connected -eq 1 ]; then
    # MacBookが開いていて、他のモニターが接続されている場合
    yabai -m config layout bsp
elif [ $builtin_display_connected -eq 0 ]; then
    # MacBookが開いている場合（クラムシェルモードではない）
    yabai -m config layout float
else
    # その他の場合
    yabai -m config layout bsp
fi
