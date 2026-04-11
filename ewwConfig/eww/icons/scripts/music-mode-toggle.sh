#!/bin/bash
# Cicla entre los tres modos: repeat → random → single → repeat
# Al entrar a un modo activa solo ese flag y apaga los demás

CURRENT=$(~/.config/eww/scripts/music-mode-get.sh)

case "$CURRENT" in
    repeat)
        # repeat → random
        mpc repeat off  > /dev/null
        mpc single off  > /dev/null
        mpc random on   > /dev/null
        ;;
    random)
        # random → single
        mpc random off  > /dev/null
        mpc repeat off  > /dev/null
        mpc single on   > /dev/null
        ;;
    single)
        # single → repeat  (estado por defecto)
        mpc single off  > /dev/null
        mpc random off  > /dev/null
        mpc repeat on   > /dev/null
        ;;
esac