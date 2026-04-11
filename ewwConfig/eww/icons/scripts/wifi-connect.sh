#!/usr/bin/env bash
# Uso: eww-wifi-connect.sh "<SSID>" "<PASSWORD>"

SSID="$1"
PASS="$2"

eww update wifi-pw-error="Conectando…"
#OUTPUT=$(nmcli dev wifi connect "${wifi-connecting-ssid}" password "${wifi-password-input}" 2>/dev/null)
OUTPUT=$(nmcli dev wifi connect "$SSID" password "$PASS" 2>&1)
STATUS=$?

if [ $STATUS -eq 0 ]; then
    eww update wifi-pw-error=""
    eww update wifi-password-input=""
    eww update wifi-show-password=false
    eww update wifi-expanded-ssid=""
    rm -f /tmp/eww-wifi-lock

else
    eww update wifi-pw-error="Contraseña incorrecta, inténtalo de nuevo"
    nmcli connection delete "$SSID"

fi
