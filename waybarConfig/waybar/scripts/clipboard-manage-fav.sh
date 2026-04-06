#!/bin/bash
# ~/.config/waybar/scripts/cliphist-manage-fav.sh
# Permite marcar/desmarcar entradas del historial como favoritas

THEME="$HOME/.config/waybar/rofi/clipboard.rasi"
FAV_FILE="$HOME/.local/share/cliphist/favorites"

mkdir -p "$(dirname "$FAV_FILE")"
touch "$FAV_FILE"

# Construir lista con contenido completo decodificado
display_list=""
declare -a encoded_list=()

while IFS=$'\t' read -r id preview; do
    # Decodificar contenido completo usando el ID
    full_content=$(printf "%s\t%s" "$id" "$preview" | cliphist decode 2>/dev/null)
    encoded=$(printf "%s" "$full_content" | base64 -w 0)

    # Preview de una línea para rofi
    display_preview=$(printf "%s" "$full_content" | tr '\n' ' ' | cut -c1-120)

    if grep -qxF "$encoded" "$FAV_FILE" 2>/dev/null; then
        display_list+="󰓎 ${display_preview}\n"
    else
        display_list+="   ${display_preview}\n"
    fi
    encoded_list+=("$encoded")
done < <(cliphist list)

if [ -z "$display_list" ]; then
    rofi -e "El historial de cliphist está vacío." -theme "$THEME"
    exit
fi

selected_display=$(printf "%b" "$display_list" | rofi -dmenu \
    -p "󱕣   Administrar Favoritos" \
    -theme "$THEME" \
    -mesg "󰓎 = favorito  |  Enter para marcar/desmarcar")

[ -z "$selected_display" ] && exit

# Buscar el índice de la línea seleccionada
index=0
while IFS= read -r line; do
    if [ "$line" = "$selected_display" ]; then
        break
    fi
    ((index++))
done < <(printf "%b" "$display_list")

encoded="${encoded_list[$index]}"
[ -z "$encoded" ] && exit

# Toggle
if grep -qxF "$encoded" "$FAV_FILE" 2>/dev/null; then
    grep -vxF "$encoded" "$FAV_FILE" > "${FAV_FILE}.tmp" && mv "${FAV_FILE}.tmp" "$FAV_FILE"
    notify-send -t 2000 "Cliphist" "Eliminado de favoritos" -i non-starred
else
    printf "%s\n" "$encoded" >> "$FAV_FILE"
    notify-send -t 2000 "Cliphist" "Agregado a favoritos" -i starred
fi