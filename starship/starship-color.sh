#!/usr/bin/env bash
source "$HOME/.cache/wal/colors.sh"

sed -i "/# WAL_START/,/# WAL_END/c\
# WAL_START\n\
[palettes.wal]\n\
color01 = \"$color12\"\n\
# WAL_END" ~/.config/starship.toml

