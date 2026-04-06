#!/bin/bash
# Elimina todo el historial

THEME="$HOME/.config/waybar/rofi/clipboard.rasi"
FAV_FILE="$HOME/.local/share/cliphist/favorites"

# Confirmar acción
confirm=$(printf "Sí, borrar\nCancelar" | rofi -dmenu \
    -p "󰆴   Borrar Todo" \
    -theme "$THEME" \
    -mesg "Se borrará todo incluyendo los favoritos")

[ "$confirm" != "Sí, borrar" ] && exit

cliphist wipe && rm -f $HOME/.local/share/cliphist/favorites

notify-send -t 2500 "Portapapeles" "Se elimino todo el Portapapeles." -i user-trash