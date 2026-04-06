#!/bin/bash
# Selector principal: muestra historial

THEME="$HOME/.config/waybar/rofi/clipboard.rasi"

selected=$(cliphist list | rofi -dmenu \
    -display-columns 2 \
    -p "󰋚 " \
    -theme "$THEME")

[ -z "$selected" ] && exit

echo "$selected" | cliphist decode | wl-copy
