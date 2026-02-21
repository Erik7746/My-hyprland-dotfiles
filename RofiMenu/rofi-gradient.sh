#!/usr/bin/env bash
set -e

# Cargar colores de pywal
source "$HOME/.cache/wal/colors.sh"

OUT="$HOME/.cache/wallpaper-selector/gradient.rasi"
mkdir -p "$(dirname "$OUT")"

# Elegimos colores (ajústalos a gusto)
GRAD_A="$color14"
GRAD_B="$color12"

cat > "$OUT" <<EOF
/* Archivo AUTOGENERADO – no editar */

element selected.normal {
    background-image: linear-gradient(45deg, ${GRAD_A}, ${GRAD_B});
}
EOF

