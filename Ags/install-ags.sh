#!/usr/bin/env bash
# ============================================================
#  install-ags.sh — Instalador de AGS (Aylur's Gtk Shell)
#  Arch Linux + Hyprland
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
ask()     { echo -en "${YELLOW}${BOLD}[ ?? ]${RESET}  $* "; }

# ── Cabecera ─────────────────────────────────────────────────
echo ""
echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}${BOLD}║    Instalador — AGS (Aylur's Gtk Shell)  ║${RESET}"
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
    gjs
    gobject-introspection
    gtk4-layer-shell
    npm
    go
    meson
    blueprint-compiler
    dart-sass
    typescript
    brightnessctl
    network-manager-applet
    pipewire
    pipewire-pulse
    wireplumber
    bluez
    bluez-utils
    jq
    gawk
    grep
    coreutils
    python
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
    aylurs-gtk-shell
    libastal-meta
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

# ── Servicios del sistema ─────────────────────────────────────
step "Habilitando servicios"

# PipeWire (usuario)
if ! systemctl --user is-active --quiet pipewire 2>/dev/null; then
    info "Habilitando PipeWire..."
    systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true
    ok "PipeWire activo."
else
    ok "PipeWire ya está activo."
fi

# Bluetooth (sistema)
if ! systemctl is-active --quiet bluetooth 2>/dev/null; then
    info "Habilitando Bluetooth..."
    sudo systemctl enable --now bluetooth 2>/dev/null || true
    ok "Bluetooth activo."
else
    ok "Bluetooth ya está activo."
fi

# ── Copiar configuración ─────────────────────────────────────
step "Instalando configuración de AGS"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGS_SRC="$SCRIPT_DIR/ags"
AGS_DEST="$HOME/.config/ags"

if [[ ! -d "$AGS_SRC" ]]; then
    error "No se encontró la carpeta 'ags' junto al script en: $AGS_SRC"
fi

# Backup si ya existe
if [[ -d "$AGS_DEST" ]]; then
    BACKUP_DIR="${AGS_DEST}.bak.$(date +%Y%m%d%H%M%S)"
    warn "AGS ya está configurado. Creando backup en: $BACKUP_DIR"
    mv "$AGS_DEST" "$BACKUP_DIR"
fi

cp -r "$AGS_SRC" "$AGS_DEST"
ok "Configuración copiada a $AGS_DEST"

# ── Dependencias npm locales ─────────────────────────────────
step "Instalando dependencias npm locales"

if [[ -f "$AGS_DEST/package.json" ]]; then
    cd "$AGS_DEST"
    npm install 2>/dev/null || warn "No se pudieron instalar dependencias npm locales. AGS puede seguir funcionando."
    ok "Dependencias npm locales instaladas."
else
    warn "No se encontró package.json en $AGS_DEST — omitiendo npm install."
fi

# ── Permisos ──────────────────────────────────────────────────
step "Aplicando permisos"

find "$AGS_DEST" -name "*.sh" -exec chmod +x {} + 2>/dev/null || true
ok "Permisos aplicados."

# ── Resumen final ────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}${BOLD}║        Instalación completada ✓          ║${RESET}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${BOLD}AGS config:${RESET}     $AGS_DEST"
echo -e "  ${BOLD}AUR helper:${RESET}     $AUR_HELPER"
echo ""
echo -e "  ${YELLOW}Próximos pasos:${RESET}"
echo -e "  1. Reinicia tu sesión de Hyprland."
echo -e "  2. Lanza AGS con:  ${BOLD}ags run${RESET}"
echo -e "  3. O inicia en background:  ${BOLD}ags run &${RESET}"
echo -e "  4. Añade el autostart en tu hyprland.conf:"
echo -e "     ${BOLD}exec-once = ags run${RESET}"
echo ""
