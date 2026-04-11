#!/bin/bash
STATUS=$(mpc status 2>/dev/null | grep -oP '(?<=\[)\w+(?=\])')
if [ "$STATUS" = "playing" ]; then
    echo "󰏤"   # ícono pausa
else
    echo "󰐊"   # ícono play
fi