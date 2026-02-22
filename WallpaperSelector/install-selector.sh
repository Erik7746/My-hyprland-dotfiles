#!/usr/bin/env bash
# ============================================================
#  install-selector.sh — Instalador del selector de Wallpapers
#  Arch Linux + Hyprland
# ============================================================

set -e

# ── Colores ──────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Rutas ────────────────────────────────────────────────────
REPO_DIR="$(cd "$(dirname "$0")" && pwd)" 
DEST="$HOME/.config"

# ── Helpers ──────────────────────────────────────────────────
info()    { echo -e "${CYAN}${BOLD}[*]${RESET} $*"; }
success() { echo -e "${GREEN}${BOLD}[✓]${RESET} $*"; }
warning() { echo -e "${YELLOW}${BOLD}[!]${RESET} $*"; }
error()   { echo -e "${RED}${BOLD}[✗]${RESET} $*"; exit 1; }

# ── Cabecera ─────────────────────────────────────────────────
echo ""
echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}${BOLD}║    Instalador — Selector de Wallpapers   ║${RESET}"
echo -e "${CYAN}${BOLD}║         Arch Linux + Hyprland            ║${RESET}"
echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════╝${RESET}"
echo ""

# ── Verificar que estamos en Arch Linux ──────────────────────
if ! command -v pacman &>/dev/null; then
    error "No se encontró pacman. ¿Estás en Arch Linux?"
fi

# ── 1. Instalar dependencias ─────────────────────────────────
info "Instalando dependencias de necesarias"

PACKAGES=(
    rofi-wayland
    swww
    imagemagick
    ffmpeg
    jq
    mpv
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

# Paquetes AUR
AUR_PACKAGES=(
    pywal
    mpvpaper
)

# Verificar que yay esté instalado
if ! command -v yay &>/dev/null; then
    warning "yay no está instalado. Instalando yay..."

    sudo pacman -S --needed --noconfirm base-devel git || error "No se pudo instalar base-devel y git"

    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm || error "No se pudo instalar yay"
    cd -
fi

TO_INSTALL_AUR=()
for pkg in "${AUR_PACKAGES[@]}"; do
    if ! pacman -Qi "$pkg" &>/dev/null; then
        TO_INSTALL_AUR+=("$pkg")
    else
        success "$pkg ya instalado (AUR)"
    fi
done

if [[ ${#TO_INSTALL_AUR[@]} -gt 0 ]]; then
    info "Instalando desde AUR: ${TO_INSTALL_AUR[*]}"
    yay -S --noconfirm "${TO_INSTALL_AUR[@]}" || error "Falló la instalación AUR"
    success "Paquetes AUR instalados"
else
    success "Todos los paquetes AUR ya estaban instalados"
fi

cp -r "$REPO_DIR/WallpaperSelector/" "$DEST/"
cp -r "$REPO_DIR/Wallpapers/" "$HOME/"
success "Archivos copiados correctamente"

echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}${BOLD}║        Instalación completada ✓          ║${RESET}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${BOLD}Selector instalado en:${RESET}  $DEST"
echo ""
echo -e "  ${YELLOW}Ejecuta wallpaper.sh para iniciar:${RESET}"
echo -e "    1. Ejecuta: chmod +x wallpaper.sh"
echo -e "    2. Puedes asignarle un atajo de teclado"
echo ""
echo -e "  ${YELLOW}Copia tus wallpapers a la carpeta 'Wallpapers' en tu home: ${RESET}"
echo ""
