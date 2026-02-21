#!/usr/bin/env bash

# ===== CONFIGURA TUS COLORES =====
THEME_NAME="Tela-circle-dracula-dark"   # nombre exacto del tema
ICON_DIR="$HOME/.local/share/icons/$THEME_NAME"

source "$HOME/.cache/wal/colors.sh"

MAIN_COLOR="$color13"        # color principal (Color de la carpeta)
BACKGROUND_COLOR="$color0"   # fondo interno
ACCENT_COLOR="$color14"      # acento extra (violeta claro)
DESKTOP_COLOR="$color12"     # color del icono de desktop
# ===== VERIFICACIONES =====
if [[ ! -d "$ICON_DIR" ]]; then
  echo "No se encontró el tema: $ICON_DIR"
  exit 1
fi

cp -r /usr/share/icons/Tela-circle-dracula ~/.local/share/icons/

echo "Recolorizando $THEME_NAME..."

# ===== PLACES (carpetas) =====
sed -i \
  -e "s/#5294e2/$MAIN_COLOR/g" \
  -e "s/#44475a/$MAIN_COLOR/g" \
  -e "s/#bd93f9/$ACCENT_COLOR/g" \
  -e "s/#f8f8f2/$BACKGROUND_COLOR/g" \
  -e "s/#dd86e0/$DESKTOP_COLOR/g"\
  -e "s/color:#ffffff/color:$BACKGROUND_COLOR/g" \
  "$ICON_DIR"/{16,22,24,32}/places/*.svg \
  "$ICON_DIR"/scalable/places/*.svg 2>/dev/null

# ===== DEVICES =====
sed -i \
  -e "s/#5294e2/$MAIN_COLOR/g" \
  -e "s/#bd93f9/$ACCENT_COLOR/g" \
  "$ICON_DIR"/{32,scalable}/devices/*.svg 2>/dev/null

# ===== ICONOS USER (Desktop, Home) =====
sed -i \
  -e "s/currentColor/$MAIN_COLOR/g" \
  "$ICON_DIR"/scalable/places/default-user-*.svg 2>/dev/null

# ===== ACTUALIZAR CACHE =====
gtk-update-icon-cache "$ICON_DIR" >/dev/null

echo "Colores aplicados correctamente"
