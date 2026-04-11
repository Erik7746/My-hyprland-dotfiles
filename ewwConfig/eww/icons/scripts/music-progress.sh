#!/bin/bash
STATUS=$(mpc status 2>/dev/null)
[ -z "$STATUS" ] && echo "0" && exit 0

TIME=$(echo "$STATUS" | grep -oP '\d+:\d+/\d+:\d+' | head -1)
[ -z "$TIME" ] && echo "0" && exit 0

CURRENT=$(echo "$TIME" | cut -d'/' -f1)
TOTAL=$(echo "$TIME" | cut -d'/' -f2)

to_sec() { echo "$1" | awk -F: '{print $1*60+$2}'; }
CURR_S=$(to_sec "$CURRENT")
TOTAL_S=$(to_sec "$TOTAL")

[ "$TOTAL_S" -eq 0 ] && echo "0" && exit 0
awk "BEGIN {printf \"%.2f\", ($CURR_S/$TOTAL_S)*100}"