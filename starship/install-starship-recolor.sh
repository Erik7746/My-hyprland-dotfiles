#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Instalando dependencias..."
PACKAGES=(
    starship
)

# Verificar cuáles ya están instalados
TO_INSTALL=()
for pkg in "${PACKAGES[@]}"; do
    if ! pacman -Qi "$pkg" &>/dev/null; then
        TO_INSTALL+=("$pkg")
    else
        echo "$pkg ya instalado"
    fi
done

if [[ ${#TO_INSTALL[@]} -gt 0 ]]; then
    info "Instalando: ${TO_INSTALL[*]}"
    sudo pacman -S --noconfirm "${TO_INSTALL[@]}" || error "Falló la instalación de paquetes"
    echo "Dependencias instaladas"
else
    echo "Todas las dependencias ya estaban instaladas"
fi

cp -r "$SCRIPT_DIR/starship.toml" "$HOME/.config/"

echo "==> Archivos de rofi agregados"

if [ -d "$HOME/.config/WallpaperSelector" ]; then
    echo "El directorio WallpaperSelector existe"
    cp -r "$SCRIPT_DIR/starship-color.sh" "$HOME/.config/WallpaperSelector/"
    echo "Se agrego los colores dinamicos"
fi