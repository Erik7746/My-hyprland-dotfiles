#!/bin/bash
# Muestra solo las entradas marcadas como favoritas

THEME="$HOME/.config/waybar/rofi/clipboard.rasi"
FAV_FILE="$HOME/.local/share/cliphist/favorites"

mkdir -p "$(dirname "$FAV_FILE")"
touch "$FAV_FILE"

if [ ! -s "$FAV_FILE" ]; then
    rofi -e "No hay favoritos guardados.\nUsa 'Administrar Favoritos' para agregar." \
        -theme "$THEME"
    exit
fi

# Decodificar cada línea base64
display_list=""
declare -a entries=()
while IFS= read -r encoded; do
    [ -z "$encoded" ] && continue
    decoded=$(printf "%s" "$encoded" | base64 -d 2>/dev/null)
    preview=$(printf "%s" "$decoded" | tr '\n' ' ' | cut -c1-120)
    display_list+="${preview}\n"
    entries+=("$encoded")
done < "$FAV_FILE"

selected_preview=$(printf "%b" "$display_list" | rofi -dmenu \
    -p "󰓎   Favoritos" \
    -theme "$THEME")

[ -z "$selected_preview" ] && exit

# Buscar el encoded que corresponde al preview seleccionado
for encoded in "${entries[@]}"; do
    decoded=$(printf "%s" "$encoded" | base64 -d 2>/dev/null)
    preview=$(printf "%s" "$decoded" | tr '\n' ' ' | cut -c1-120)
    if [ "$preview" = "$selected_preview" ]; then
        printf "%s" "$decoded" | wl-copy
        exit
    fi
done