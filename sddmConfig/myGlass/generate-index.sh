#!/usr/bin/env bash
# ============================================================
# generate-index.sh
# Genera el archivo backgrounds/index.txt con todos los fondos
# (imágenes y videos) encontrados en la carpeta backgrounds/.
#
# Uso:
#   cd /usr/share/sddm/themes/TuTema
#   bash generate-index.sh
#
# Ejecutar cada vez que añadas o quites archivos de backgrounds/
# ============================================================

THEME_DIR="$(cd "$(dirname "$0")" && pwd)"
BG_DIR="$THEME_DIR/backgrounds"
INDEX="$BG_DIR/index.txt"

# Extensiones soportadas
EXTS=("png" "jpg" "jpeg" "bmp" "webp" "gif" "mp4" "webm" "mkv" "avi" "mov")

if [ ! -d "$BG_DIR" ]; then
    echo "Error: No se encontró la carpeta backgrounds/ en $THEME_DIR"
    exit 1
fi

# Limpia el index anterior
> "$INDEX"

for ext in "${EXTS[@]}"; do
    # Busca en minúsculas y mayúsculas
    find "$BG_DIR" -maxdepth 1 -type f \( -iname "*.${ext}" \) | while read -r filepath; do
        basename "$filepath" >> "$INDEX"
    done
done

# Ordena y elimina duplicados
sort -u "$INDEX" -o "$INDEX"

COUNT=$(wc -l < "$INDEX")
echo "✓ index.txt generado con $COUNT archivo(s) en backgrounds/"
echo ""
cat "$INDEX"
