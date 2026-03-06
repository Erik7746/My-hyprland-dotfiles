#!/bin/bash
STATUS=$(mpc status 2>/dev/null)
TIME=$(echo "$STATUS" | grep -oP '\d+:\d+/\d+:\d+' | head -1)

if [ -z "$TIME" ]; then
    echo "0:00 / 0:00"
else
    CUR=$(echo "$TIME" | cut -d'/' -f1)
    TOT=$(echo "$TIME" | cut -d'/' -f2)
    echo "$CUR / $TOT"
fi