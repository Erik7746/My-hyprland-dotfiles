#!/bin/bash
COVER_CACHE="/tmp/eww_music_cover.png"
DEFAULT_COVER="$HOME/.config/eww/assets/music-default.png"
MPD_MUSIC_DIR="${MPD_MUSIC_DIR:-$HOME/musicas}"
SIZE=300  # tamaño del cuadrado final en píxeles

CURRENT_FILE=$(mpc -f "%file%" current 2>/dev/null)
[ -z "$CURRENT_FILE" ] && echo "$DEFAULT_COVER" && exit 0

FULL_PATH="$MPD_MUSIC_DIR/$CURRENT_FILE"
SONG_DIR=$(dirname "$FULL_PATH")

HASH_FILE="/tmp/eww_music_cover.hash"
CURRENT_HASH=$(echo "$CURRENT_FILE" | md5sum | cut -d' ' -f1)
STORED_HASH=$(cat "$HASH_FILE" 2>/dev/null)
if [ "$CURRENT_HASH" = "$STORED_HASH" ] && [ -f "$COVER_CACHE" ]; then
    echo "$COVER_CACHE" && exit 0
fi

# Filtro ffmpeg: toma el lado más corto como referencia,
# escala manteniendo proporción y luego recorta al centro en cuadrado
SQUARE_FILTER="scale='if(gt(iw,ih),-1,$SIZE)':'if(gt(iw,ih),$SIZE,-1)',crop=$SIZE:$SIZE"

# 1. Portada embebida en el archivo de audio
if ffmpeg -i "$FULL_PATH" -an -vf "$SQUARE_FILTER" \
    "$COVER_CACHE" -y 2>/dev/null; then
    echo "$CURRENT_HASH" > "$HASH_FILE"
    echo "$COVER_CACHE" && exit 0
fi

# 2. Buscar imagen en la carpeta del álbum
for name in cover.png cover.jpg Cover.png Cover.jpg folder.jpg folder.png album.jpg artwork.png; do
    if [ -f "$SONG_DIR/$name" ]; then
        ffmpeg -i "$SONG_DIR/$name" -vf "$SQUARE_FILTER" \
            "$COVER_CACHE" -y 2>/dev/null
        echo "$CURRENT_HASH" > "$HASH_FILE"
        echo "$COVER_CACHE" && exit 0
    fi
done

# 3. Fallback
echo "$DEFAULT_COVER"
```

---

El truco está en el filtro:
```
scale='if(gt(iw,ih),-1,300)':'if(gt(iw,ih),300,-1)',crop=300:300