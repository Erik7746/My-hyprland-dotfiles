#!/usr/bin/env bash
# ============================================================
#  globalcontrol.sh — Variables globales para scripts HyDE
#  Fallback mínimo para waybar/wlogout
# ============================================================

# Directorios
export confDir="${confDir:-$HOME/.config}"
export HYDE_CACHE_HOME="${HYDE_CACHE_HOME:-$HOME/.cache/hyde}"

# Estilo wlogout
export WLOGOUT_STYLE="${WLOGOUT_STYLE:-1}"

# Tema y colores
export HYDE_THEME="${HYDE_THEME:-}"
export HYDE_THEME_DIR="${HYDE_THEME_DIR:-$confDir/hyde/themes/$HYDE_THEME}"
export enableWallDcol="${enableWallDcol:-1}"

# Bordes Hyprland
export hypr_border="${hypr_border:-10}"

# Función auxiliar: leer valor de hyprland.conf
get_hyprConf() {
    local key="$1"
    local conf="${confDir}/hypr/hyprland.conf"
    [ -f "$conf" ] || return
    grep -m1 -E "^\s*${key}\s*=" "$conf" | sed -E 's/.*=\s*//' | tr -d ' '"\t"
}
