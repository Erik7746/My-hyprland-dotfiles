#!/bin/bash
# Lista canciones en el mismo orden que MPD las serviría (sorted)

mpc listall -f "%file%\t%title%\t%artist%" 2>/dev/null \
| sort \
| awk -F'\t' '
BEGIN { print "[" }
{
    file = $1
    title = (length($2) > 0 ? $2 : gensub(/.*\//, "", "g", $1))
    artist = (length($3) > 0 ? $3 : "Desconocido")

    gsub(/"/, "\\\"", file)
    gsub(/"/, "\\\"", title)
    gsub(/"/, "\\\"", artist)

    if (NR > 1) printf ",\n"
    printf "  {\"file\":\"%s\",\"title\":\"%s\",\"artist\":\"%s\"}", file, title, artist
}
END { print "\n]" }' 2>/dev/null || echo "[]"
