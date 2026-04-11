#!/bin/bash
# Lee el estado actual de MPD y devuelve el modo activo + ícono

status=$(mpc status 2>/dev/null)

repeat=$(echo "$status" | grep -oP 'repeat: \K\w+')
random=$(echo "$status" | grep -oP 'random: \K\w+')
single=$(echo "$status" | grep -oP 'single: \K\w+')

if   [ "$random" = "on" ]; then echo "random"
elif [ "$single" = "on" ]; then echo "single"
else                             echo "repeat" 
fi