#!/bin/bash
# Reproduce una canción manteniendo el orden natural de la biblioteca
# Uso: music-play.sh "ruta/cancion.mp3"

FILE="$1"
[ -z "$FILE" ] && exit 1

QUEUE_SIZE=$(mpc playlist 2>/dev/null | wc -l)
LIBRARY_SIZE=$(mpc listall 2>/dev/null | wc -l)

# ── Si la queue no coincide con la biblioteca completa, recargarla ────────────
if [ "$QUEUE_SIZE" -ne "$LIBRARY_SIZE" ]; then
    mpc clear > /dev/null
    mpc listall | mpc add > /dev/null
fi

# ── Buscar la posición exacta del archivo en la queue ─────────────────────────
# mpc playlist devuelve "pos) file" con --format
POS=$(mpc playlist --format "%position% %file%" 2>/dev/null \
    | awk -v target="$FILE" '
        index($0, target) {
            print $1
            exit
        }
    ')

if [ -z "$POS" ]; then
    echo "Error: canción no encontrada en queue" >&2
    exit 1
fi

mpc play "$POS" > /dev/null
