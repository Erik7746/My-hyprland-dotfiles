#!/usr/bin/env bash
# ============================================================
#  install-waybar.sh — Instalador de Waybar para Arch Linux
#  Hyprland Dotfiles
# ============================================================

set -euo pipefail

# ── Colores ──────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Helpers ──────────────────────────────────────────────────
info()    { echo -e "${BLUE}${BOLD}[INFO]${RESET}  $*"; }
ok()      { echo -e "${GREEN}${BOLD}[ OK ]${RESET}  $*"; }
warn()    { echo -e "${YELLOW}${BOLD}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}${BOLD}[ERR ]${RESET}  $*" >&2; exit 1; }
step()    { echo -e "\n${CYAN}${BOLD}══ $* ══${RESET}"; }

# ── Cabecera ─────────────────────────────────────────────────
echo ""
echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}${BOLD}║    Instalador — Waybar (HyDE style)      ║${RESET}"
echo -e "${CYAN}${BOLD}║         Arch Linux + Hyprland            ║${RESET}"
echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════╝${RESET}"
echo ""

# ── Comprobaciones iniciales ───────────────────────────────────
step "Comprobaciones previas"

if [[ $EUID -eq 0 ]]; then
    error "No ejecutes este script como root. Se pedirá sudo cuando sea necesario."
fi

if ! command -v pacman &>/dev/null; then
    error "Este script es exclusivo para Arch Linux (pacman no encontrado)."
fi

ok "Usuario: $(whoami) | Sistema: Arch Linux detectado"

# ── Detectar AUR helper ───────────────────────────────────────
step "Detectando AUR helper"

AUR_HELPER=""
for helper in yay paru pikaur trizen; do
    if command -v "$helper" &>/dev/null; then
        AUR_HELPER="$helper"
        ok "AUR helper encontrado: $AUR_HELPER"
        break
    fi
done

if [[ -z "$AUR_HELPER" ]]; then
    warn "No se encontró un AUR helper. Instalando 'yay'..."
    sudo pacman -S --needed --noconfirm base-devel git
    TMPDIR_YAY=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$TMPDIR_YAY/yay"
    (cd "$TMPDIR_YAY/yay" && makepkg -si --noconfirm)
    rm -rf "$TMPDIR_YAY"
    AUR_HELPER="yay"
    ok "yay instalado correctamente."
fi

# ── Paquetes oficiales ───────────────────────────────────────
step "Instalando paquetes de repositorios oficiales"

OFFICIAL_PKGS=(
    waybar
    rofi-wayland
    playerctl
    brightnessctl
    network-manager-applet
    wl-clipboard
    jq
    gawk
    grep
    coreutils
    python
    pavucontrol
)

TO_INSTALL=()
for pkg in "${OFFICIAL_PKGS[@]}"; do
    if ! pacman -Qi "$pkg" &>/dev/null; then
        TO_INSTALL+=("$pkg")
    else
        ok "$pkg ya instalado"
    fi
done

if [[ ${#TO_INSTALL[@]} -gt 0 ]]; then
    info "Instalando: ${TO_INSTALL[*]}"
    sudo pacman -S --needed --noconfirm "${TO_INSTALL[@]}"
    ok "Paquetes oficiales instalados."
else
    ok "Todos los paquetes oficiales ya estaban instalados."
fi

# ── Paquetes AUR ─────────────────────────────────────────────
step "Instalando paquetes desde AUR"

AUR_PKGS=(
    wlogout
)

TO_INSTALL_AUR=()
for pkg in "${AUR_PKGS[@]}"; do
    if ! pacman -Qi "$pkg" &>/dev/null; then
        TO_INSTALL_AUR+=("$pkg")
    else
        ok "$pkg ya instalado (AUR)"
    fi
done

if [[ ${#TO_INSTALL_AUR[@]} -gt 0 ]]; then
    info "Instalando desde AUR: ${TO_INSTALL_AUR[*]}"
    "$AUR_HELPER" -S --needed --noconfirm "${TO_INSTALL_AUR[@]}"
    ok "Paquetes AUR instalados."
else
    ok "Todos los paquetes AUR ya estaban instalados."
fi

# ── Copiar configuración ─────────────────────────────────────
step "Instalando configuración de Waybar"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WAYBAR_SRC="$SCRIPT_DIR/waybar"
WAYBAR_DEST="$HOME/.config/waybar"

if [[ ! -d "$WAYBAR_SRC" ]]; then
    error "No se encontró la carpeta 'waybar' junto al script en: $WAYBAR_SRC"
fi

# Backup si ya existe
if [[ -d "$WAYBAR_DEST" ]]; then
    BACKUP_DIR="${WAYBAR_DEST}.bak.$(date +%Y%m%d%H%M%S)"
    warn "Waybar ya está configurado. Creando backup en: $BACKUP_DIR"
    mv "$WAYBAR_DEST" "$BACKUP_DIR"
fi

cp -r "$WAYBAR_SRC" "$WAYBAR_DEST"
ok "Configuración copiada a $WAYBAR_DEST"

# ── Permisos de scripts ──────────────────────────────────────
step "Aplicando permisos de ejecución"

SCRIPTS_DIR="$WAYBAR_DEST/scripts"
if [[ -d "$SCRIPTS_DIR" ]]; then
    chmod +x "$SCRIPTS_DIR/"*.sh 2>/dev/null || true
    ok "Permisos de ejecución aplicados a scripts/"
fi

WLOGOUT_SCRIPTS="$WAYBAR_DEST/wlogout"
if [[ -d "$WLOGOUT_SCRIPTS" ]]; then
    # wlogout no suele tener scripts .sh, pero por si acaso
    find "$WLOGOUT_SCRIPTS" -name "*.sh" -exec chmod +x {} + 2>/dev/null || true
    ok "Permisos de ejecución aplicados a wlogout/"
fi

# ── Resumen final ────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}${BOLD}║        Instalación completada ✓          ║${RESET}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${BOLD}Waybar config:${RESET}  $WAYBAR_DEST"
echo -e "  ${BOLD}AUR helper:${RESET}     $AUR_HELPER"
echo ""
echo -e "  ${YELLOW}Próximos pasos:${RESET}"
echo -e "  1. Reinicia Waybar o tu sesión de Hyprland."
echo -e "  2. Si usas wlogout, asegúrate de tenerlo disponible en PATH."
echo -e "  3. Personaliza los módulos en: ${BOLD}$WAYBAR_DEST/modules/${RESET}"
echo ""
