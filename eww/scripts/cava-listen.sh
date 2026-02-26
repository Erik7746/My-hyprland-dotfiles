#!/bin/bash
# cava-listen.sh — escribe JSON a stdout para deflisten de eww
# eww lo consume con: (deflisten bars_data `bash cava-listen.sh`)
# Requiere: cava, awk

CAVA_FIFO="/tmp/cava_fifo"
BARS=10
MAX_HEIGHT=80
FRAMERATE=30

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

# Emitir un JSON inicial para que eww no quede en blanco
echo '{"b1":2,"b2":2,"b3":2,"b4":2,"b5":2,"b6":2,"b7":2,"b8":2,"b9":2,"b10":2}'

# Todo el smoothing + JSON en UN solo proceso awk persistente
# awk lee el FIFO línea a línea — no hay forks, no hay subshells
awk -v MAX=$MAX_HEIGHT -v ATTACK=0.8 -v DECAY=0.18 '
BEGIN {
    # Estado inicial de las 10 barras
    for (i = 1; i <= 10; i++) cur[i] = 2
}
{
    # Parsear los 10 valores separados por ";"
    n = split($0, raw, ";")

    for (i = 1; i <= 10; i++) {
        target = (i <= n) ? int(raw[i]) : 0

        # Clamp target
        if (target < 0)   target = 0
        if (target > MAX) target = MAX

        # Smoothing asimétrico: ataque rápido, decay lento
        if (target > cur[i]) {
            cur[i] = cur[i] + ATTACK * (target - cur[i])
        } else {
            cur[i] = cur[i] - DECAY * cur[i]
        }

        # Clamp resultado: mínimo 2px, máximo MAX
        if (cur[i] < 2)   cur[i] = 2
        if (cur[i] > MAX) cur[i] = MAX

        val[i] = int(cur[i])
    }

    # Emitir JSON en una sola línea → deflisten recibe 1 valor por frame
    printf "{\"b1\":%d,\"b2\":%d,\"b3\":%d,\"b4\":%d,\"b5\":%d,\"b6\":%d,\"b7\":%d,\"b8\":%d,\"b9\":%d,\"b10\":%d}\n",
        val[1],val[2],val[3],val[4],val[5],val[6],val[7],val[8],val[9],val[10]
    fflush()   # forzar flush para que eww reciba cada línea al instante
}
' < "$CAVA_FIFO"
