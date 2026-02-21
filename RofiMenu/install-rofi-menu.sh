#!/usr/bin/env bash

set -e

echo "==> Instalando dependencias..."
PACKAGES=(
    rofi-wayland
)

# Verificar cuáles ya están instalados
TO_INSTALL=()
for pkg in "${PACKAGES[@]}"; do
    if ! pacman -Qi "$pkg" &>/dev/null; then
        TO_INSTALL+=("$pkg")
    else
        success "$pkg ya instalado"
    fi
done

if [[ ${#TO_INSTALL[@]} -gt 0 ]]; then
    info "Instalando: ${TO_INSTALL[*]}"
    sudo pacman -S --noconfirm "${TO_INSTALL[@]}" || error "Falló la instalación de paquetes"
    success "Dependencias instaladas"
else
    success "Todas las dependencias ya estaban instaladas"
fi

cp -r "$SCRIPT_DIR/rofi" "$HOME/.config/"
echo "==> Archivos de rofi agregados"

if [ -d "$HOME/.config/WallpaperSelector" ]; then
    echo "El directorio WallpaperSelector existe"
    cp -r "$SCRIPT_DIR/rofi-gradient.sh" "$HOME/.config/WallpaperSelector/"
    echo "Se agrego los colores dinamicos"
fi