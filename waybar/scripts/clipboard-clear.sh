#!/bin/bash
# Limpia todo el historial a excepecion de los favoritos

THEME="$HOME/.config/waybar/rofi/clipboard.rasi"
FAV_FILE="$HOME/.local/share/cliphist/favorites"

confirm=$(printf "Sí, borrar\nCancelar" | rofi -dmenu \
    -p "󰆴   Limpiar Historial" \
    -theme "$THEME" \
    -mesg "Se borrará todo excepto los favoritos")

[ "$confirm" != "Sí, borrar" ] && exit

# Leer y decodificar favoritos antes de borrar
declare -a favs=()
if [ -f "$FAV_FILE" ] && [ -s "$FAV_FILE" ]; then
    while IFS= read -r encoded; do
        [ -z "$encoded" ] && continue
        decoded=$(printf "%s" "$encoded" | base64 -d 2>/dev/null)
        favs+=("$decoded")
    done < "$FAV_FILE"
fi

cliphist wipe

# Re-insertar favoritos: copiar al portapapeles y dejar que wl-paste+cliphist store
# los capture automáticamente via el hook de Hyprland, o forzarlo manualmente
for content in "${favs[@]}"; do
    printf "%s" "$content" | wl-copy
    sleep 0.2  # dar tiempo a que cliphist capture la entrada via el hook
done

# Restaurar el último favorito en el portapapeles
if [ ${#favs[@]} -gt 0 ]; then
    printf "%s" "${favs[-1]}" | wl-copy
fi

notify-send -t 2500 "Cliphist" "Historial limpiado. Favoritos conservados: ${#favs[@]}" -i user-trash
