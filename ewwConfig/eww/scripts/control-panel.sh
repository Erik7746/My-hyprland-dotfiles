#!/bin/bash
# ~/.config/eww/scripts/control-panel.sh
# Uso: control-panel.sh [toggle-panel|toggle-wifi|overlay|overlay_list]

TRIGGER="$1"

close_win() { eww close "$1" 2>/dev/null; }
open_win()  { eww open  "$1" 2>/dev/null; }
is_open()   { eww active-windows 2>/dev/null | grep -q "$1"; }

case "$TRIGGER" in
    toggle-panel)
        if is_open "control-panel"; then
            close_win "control-panel"
            close_win "overlay"
        else
            open_win "control-panel"
            open_win "overlay"
        fi
        ;;
    #caso no usado temporalmente
    toggle-wifi)
        if is_open "wifi-networks-window"; then
            close_win "wifi-networks-window"
            close_win "overlay_list"
        else
            open_win "wifi-networks-window"
            open_win "overlay_list"
        fi
        ;;
    overlay)
        close_win "control-panel"
        close_win "overlay"
        close_win "wifi-networks-window"
        close_win "overlay_list"
        ;;
    overlay_list)
        close_win "wifi-networks-window"
        close_win "overlay_list"
        ;;
    *)
        echo "Uso: $0 [toggle-panel|toggle-wifi|overlay|overlay_list]"
        exit 1
        ;;
esac