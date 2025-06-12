#!/bin/bash

UUID="0A9C5967-4500-41CC-B9F4-4AF6557F454E"

yabai -m query --displays | grep -q "$UUID"
if [ $? -eq 0 ]; then
    # echo connected >>~/dotfiles/log.txt
    yabai -m config layout float
else
    # echo disconnected >>~/dotfiles/log.txt
    yabai -m config layout bsp
fi
