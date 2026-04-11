#!/bin/bash
# Genera el fondo dinámico desenfocado a partir de la portada actual
# Requiere: mpc, ffmpeg, imagemagick (convert)

BG_CACHE="/tmp/eww_music_bg.png"
DEFAULT_COVER="$HOME/.config/eww/assets/music-default.png"
MPD_MUSIC_DIR="${MPD_MUSIC_DIR:-$HOME/musicas}"
PANEL_W=380
PANEL_H=680

CURRENT_FILE=$(mpc -f "%file%" current 2>/dev/null)
if [ -z "$CURRENT_FILE" ]; then
    # Generar fondo oscuro por defecto si no hay música
    convert -size "${PANEL_W}x${PANEL_H}" xc:"#0f0f14" "$BG_CACHE" 2>/dev/null
    echo "$BG_CACHE" && exit 0
fi

FULL_PATH="$MPD_MUSIC_DIR/$CURRENT_FILE"
SONG_DIR=$(dirname "$FULL_PATH")

# Evitar re-generación si la canción no cambió
HASH_FILE="/tmp/eww_music_bg.hash"
CURRENT_HASH=$(echo "$CURRENT_FILE" | md5sum | cut -d' ' -f1)
STORED_HASH=$(cat "$HASH_FILE" 2>/dev/null)
if [ "$CURRENT_HASH" = "$STORED_HASH" ] && [ -f "$BG_CACHE" ]; then
    echo "$BG_CACHE" && exit 0
fi

RAW_COVER="/tmp/eww_music_raw_cover.png"

# ── Extraer imagen fuente ──────────────────────────────────────────────────────
extracted=false

# 1. Portada embebida en el audio
if ffmpeg -i "$FULL_PATH" -an -vcodec png -vframes 1 "$RAW_COVER" -y 2>/dev/null; then
    extracted=true
fi

# 2. Imagen suelta en la carpeta del álbum
if [ "$extracted" = false ]; then
    for name in cover.png cover.jpg Cover.png Cover.jpg folder.jpg folder.png album.jpg artwork.png; do
        if [ -f "$SONG_DIR/$name" ]; then
            cp "$SONG_DIR/$name" "$RAW_COVER"
            extracted=true
            break
        fi
    done
fi

# 3. Imagen por defecto
if [ "$extracted" = false ]; then
    cp "$DEFAULT_COVER" "$RAW_COVER"
fi

# ── Procesar con ImageMagick ───────────────────────────────────────────────────
#
#  Pasos:
#  1. -gravity Center -crop 65%x65%  → zoom al centro (descarta bordes)
#  2. -resize WxH^  +  -extent WxH   → escala para cubrir el panel completo
#  3. -blur 0x50                      → desenfoque gaussiano de 50px
#  4. -modulate 80,140                → brillo 80% (-20) · saturación 140% (+40)
#
convert "$RAW_COVER" \
    -gravity Center \
    -crop 65%x65%+0+0 +repage \
    -resize "${PANEL_W}x${PANEL_H}^" \
    -gravity Center \
    -extent "${PANEL_W}x${PANEL_H}" \
    -blur 0x50 \
    -modulate 80,140 \
    "$BG_CACHE" 2>/dev/null

echo "$CURRENT_HASH" > "$HASH_FILE"
echo "$BG_CACHE"