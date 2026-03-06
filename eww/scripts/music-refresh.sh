#!/bin/bash
# Actualiza la queue de MPD sin interrumpir la reproducción actual
# Estrategia:
#   1. mpc crop  → deja solo la canción actual reproduciéndose (sin pausa)
#   2. Obtiene la lista completa ordenada desde MPD
#   3. Añade primero las canciones DESPUÉS de la actual (orden natural)
#   4. Añade después las canciones ANTES de la actual (cierre del ciclo)
#   → Resultado: cola circular correcta desde la posición actual

CURRENT_FILE=$(mpc -f "%file%" current 2>/dev/null)

if [ -z "$CURRENT_FILE" ]; then
    # No hay nada reproduciéndose — cargar toda la biblioteca limpia
    mpc clear > /dev/null
    mpc listall | mpc add > /dev/null
    exit 0
fi

# Obtener lista completa ordenada
LIBRARY=$(mpc listall 2>/dev/null)
TOTAL=$(echo "$LIBRARY" | wc -l)

if [ "$TOTAL" -eq 0 ]; then
    exit 0
fi

# Encontrar la posición de la canción actual en la biblioteca
CURRENT_IDX=$(echo "$LIBRARY" | grep -n "^${CURRENT_FILE}$" | cut -d: -f1 | head -1)

if [ -z "$CURRENT_IDX" ]; then
    # La canción actual ya no existe en la biblioteca — recargar todo
    mpc clear > /dev/null
    echo "$LIBRARY" | mpc add > /dev/null
    exit 0
fi

# ── Reconstruir queue sin interrumpir ────────────────────────────────────────

# Dejar solo la canción actual en la queue (sigue sonando)
mpc crop > /dev/null

# Canciones DESPUÉS de la actual (continúan el orden natural)
AFTER=$(echo "$LIBRARY" | tail -n +"$((CURRENT_IDX + 1))")
if [ -n "$AFTER" ]; then
    echo "$AFTER" | mpc add > /dev/null
fi

# Canciones ANTES de la actual (cierran el ciclo al final)
BEFORE=$(echo "$LIBRARY" | head -n "$((CURRENT_IDX - 1))")
if [ -n "$BEFORE" ]; then
    echo "$BEFORE" | mpc add > /dev/null
fi

# Resultado:  [actual★] [B] [C] ... [A]
#             pos 1 sigue sonando, orden circular preservado