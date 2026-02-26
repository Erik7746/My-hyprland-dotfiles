#!/bin/bash
# cava-eww.sh — ultra optimizado
#  - Solo 10 barras a eww (espejo dentro de eww = 20 visuales)
#  - Smoothing: ataque rápido, decay lento
# Requiere: cava, eww, mpd/mpc

CAVA_FIFO="/tmp/cava_fifo"
BARS=8         # cava genera 10, eww las espeja a 20
MAX_HEIGHT=80
FRAMERATE=20

# --- Smoothing ---
# ATTACK: qué fracción del salto SUBIMOS por frame  (1.0 = instantáneo)
# DECAY:  qué fracción de la altura BAJAMOS por frame (menor = más lento)
ATTACK="0.8"   # sube al 80% de la diferencia en 1 frame → casi instantáneo
DECAY="0.18"   # baja 18% por frame → caída suave (~5-6 frames hasta 0)

CAVA_CONFIG="/tmp/cava_eww.conf"
cat > "$CAVA_CONFIG" << EOF
[general]
bars = $BARS
framerate = $FRAMERATE
sensitivity = 100
lower_cutoff_freq = 50
higher_cutoff_freq = 10000

[output]
method = raw
raw_target = $CAVA_FIFO
data_format = ascii
ascii_max_range = $MAX_HEIGHT
bit_format = 8bit

[smoothing]
monstercat = 1
waves = 0
noise_reduction = 0.6
EOF

[ -p "$CAVA_FIFO" ] || mkfifo "$CAVA_FIFO"
pkill -f "cava -p $CAVA_CONFIG" 2>/dev/null
sleep 0.1

cava -p "$CAVA_CONFIG" &
CAVA_PID=$!
trap "kill $CAVA_PID 2>/dev/null; rm -f $CAVA_FIFO $CAVA_CONFIG" EXIT

# Estado previo de las 10 barras (para el smoothing)
declare -a prev=(2 2 2 2 2 2 2 2 2 2)

while IFS=';' read -ra raw; do
    args=""
    for i in $(seq 0 9); do
        target="${raw[$i]:-0}"
        cur="${prev[$i]}"

        # Ataque: si el target es MAYOR, subimos rápido
        # Decay:  si el target es MENOR, bajamos lento
        if (( target > cur )); then
            # new = cur + ATTACK * (target - cur)   → bash no tiene floats, usamos awk
            new=$(awk "BEGIN{v=${cur}+${ATTACK}*(${target}-${cur}); printf \"%d\", (v>=${MAX_HEIGHT}?${MAX_HEIGHT}:v)}")
        else
            # new = cur - DECAY * cur
            new=$(awk "BEGIN{v=${cur}-${DECAY}*${cur}; printf \"%d\", (v<=2?2:v)}")
        fi

        prev[$i]=$new
        args+="bar$((i+1))=${new} "
    done

    # 1 sola llamada con las 10 barras
    eww update $args 2>/dev/null
done < "$CAVA_FIFO"