#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════
#  install-ags-packages.sh — Instalador completo de entorno AGS
#  Arch Linux + Hyprland
#
#  Coloca este script junto a las carpetas de configuración:
#    ags/ dunst/ mpd/ mpDris2/ waybar/ cava/ mpc/ kitty/
#  Excepción: hypr/ NO se toca (debe gestionarse manualmente)
# ═══════════════════════════════════════════════════════════════════════

set -euo pipefail

# ── Colores ──────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Helpers ──────────────────────────────────────────────────────────
info()    { echo -e "${BLUE}${BOLD}[INFO]${RESET}  $*"; }
ok()      { echo -e "${GREEN}${BOLD}[ OK ]${RESET}  $*"; }
warn()    { echo -e "${YELLOW}${BOLD}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}${BOLD}[ERR ]${RESET} $*" >&2; exit 1; }
step()    { echo -e "\n${CYAN}${BOLD}══ $* ══${RESET}"; }

# ── Cabecera ─────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}${BOLD}║    Instalador completo — AGS (Aylur's Gtk Shell)     ║${RESET}"
echo -e "${CYAN}${BOLD}║              Arch Linux + Hyprland                   ║${RESET}"
echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════════════╝${RESET}"
echo ""

# ── Comprobaciones iniciales ─────────────────────────────────────────
step "Comprobaciones previas"

if [[ $EUID -eq 0 ]]; then
    error "No ejecutes este script como root. Se usará sudo cuando sea necesario."
fi

if ! command -v pacman &>/dev/null; then
    error "Este script es exclusivo para Arch Linux (pacman no encontrado)."
fi

ok "Usuario: $(whoami) | Sistema: Arch Linux detectado"

# ── Detectar AUR helper ──────────────────────────────────────────────
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

# ── Paquetes oficiales ───────────────────────────────────────────────
step "Instalando paquetes de repositorios oficiales"

OFFICIAL_PKGS=(
    # AGS / GTK4 / Build
    gjs
    gobject-introspection
    gtk4-layer-shell
    npm
    go
    meson
    blueprint-compiler
    dart-sass
    typescript
    libadwaita

    # Hyprland ecosystem
    xdg-desktop-portal-hyprland

    # Audio / PipeWire
    pipewire
    pipewire-pulse
    wireplumber
    libpulse          # pactl

    # Red / Bluetooth
    networkmanager
    bluez
    bluez-utils

    # Hardware
    brightnessctl

    # Música / Media
    mpd
    mpc
    mpdris2
    ffmpeg
    playerctl

    # Visualizador
    cava

    # Notificaciones / Barra / Apps
    dunst
    waybar
    kitty
    dolphin
    rofi

    # Utilidades Hyprland usadas por la config
    wl-clipboard
    cliphist

    # Básicos
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

# ── Paquetes AUR ─────────────────────────────────────────────────────
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

# ── Servicios del sistema ────────────────────────────────────────────
step "Habilitando servicios esenciales"

# NetworkManager
if ! systemctl is-active --quiet NetworkManager 2>/dev/null; then
    info "Habilitando NetworkManager..."
    sudo systemctl enable --now NetworkManager 2>/dev/null || true
    ok "NetworkManager activo."
else
    ok "NetworkManager ya está activo."
fi

# Bluetooth
if ! systemctl is-active --quiet bluetooth 2>/dev/null; then
    info "Habilitando Bluetooth..."
    sudo systemctl enable --now bluetooth 2>/dev/null || true
    ok "Bluetooth activo."
else
    ok "Bluetooth ya está activo."
fi

# PipeWire (usuario)
if ! systemctl --user is-active --quiet pipewire 2>/dev/null; then
    info "Habilitando PipeWire..."
    systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true
    ok "PipeWire activo."
else
    ok "PipeWire ya está activo."
fi

# MPD (usuario)
if ! systemctl --user is-active --quiet mpd 2>/dev/null; then
    info "Habilitando MPD..."
    systemctl --user enable --now mpd 2>/dev/null || true
    ok "MPD activo."
else
    ok "MPD ya está activo."
fi

# ── Preparar rutas ───────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_HOME="$HOME"
CONFIG_HOME="$HOME/.config"

# ── Función: sincronizar directorio de config ────────────────────────
sync_config_dir() {
    local name="$1"
    local src="$SCRIPT_DIR/$name"
    local dest="$CONFIG_HOME/$name"

    if [ ! -d "$src" ]; then
        return 0
    fi

    info "Replicando $name..."
    mkdir -p "$dest"

    if command -v rsync &>/dev/null; then
        rsync -a --delete \
            --exclude='.git' \
            --exclude='node_modules' \
            "$src/" "$dest/"
    else
        find "$dest" -mindepth 1 -not -path "$dest/node_modules/*" -not -path "$dest/node_modules" -delete 2>/dev/null || true
        cp -r "$src"/* "$dest/" 2>/dev/null || true
        rm -rf "$dest/.git"
    fi

    ok "$name → $dest"
}

# ── Replicar configs auxiliares ────────────────────────────────────────
step "Replicando configuraciones auxiliares"

AUX_CONFIGS=(dunst mpDris2 waybar cava mpc kitty)
for cfg in "${AUX_CONFIGS[@]}"; do
    sync_config_dir "$cfg"
done

# ── Replicar mpd (excluir archivos de runtime) ─────────────────────────
if [ -d "$SCRIPT_DIR/mpd" ]; then
    info "Replicando mpd (sin archivos de runtime)..."
    mkdir -p "$CONFIG_HOME/mpd"

    if command -v rsync &>/dev/null; then
        rsync -a --delete \
            --exclude='.git' \
            --exclude='log' \
            --exclude='pid' \
            --exclude='socket' \
            "$SCRIPT_DIR/mpd/" "$CONFIG_HOME/mpd/"
    else
        find "$CONFIG_HOME/mpd" -mindepth 1 -not -path "$CONFIG_HOME/mpd/playlists/*" -not -path "$CONFIG_HOME/mpd/playlists" -delete 2>/dev/null || true
        for item in "$SCRIPT_DIR/mpd"/*; do
            [ -e "$item" ] || continue
            base=$(basename "$item")
            [[ "$base" == "log" || "$base" == "pid" || "$base" == "socket" ]] && continue
            if [ -d "$item" ]; then
                cp -r "$item" "$CONFIG_HOME/mpd/"
            else
                cp "$item" "$CONFIG_HOME/mpd/"
            fi
        done
    fi

    ok "mpd → $CONFIG_HOME/mpd"
fi

# ── Replicar ags (manejo especial) ───────────────────────────────────
AGS_SRC="$SCRIPT_DIR/ags"
AGS_DEST="$CONFIG_HOME/ags"

if [[ ! -d "$AGS_SRC" ]]; then
    error "No se encontró la carpeta 'ags' junto al script en: $AGS_SRC"
fi

step "Replicando ags"

mkdir -p "$AGS_DEST"

if command -v rsync &>/dev/null; then
    rsync -a --delete \
        --exclude='.git' \
        --exclude='node_modules' \
        --exclude='.gitignore' \
        "$AGS_SRC/" "$AGS_DEST/"
else
    find "$AGS_DEST" -mindepth 1 -not -path "$AGS_DEST/node_modules/*" -not -path "$AGS_DEST/node_modules" -delete 2>/dev/null || true
    cp -r "$AGS_SRC"/* "$AGS_DEST/" 2>/dev/null || true
    rm -rf "$AGS_DEST/.git"
fi

ok "Archivos copiados (node_modules preservado si existía)"

# ── Hardcodear rutas del usuario ─────────────────────────────────────
step "Ajustando rutas hardcodeadas"

PATCH_FILES=(
    "$AGS_DEST/lib/music.ts"
)

PATCHED_COUNT=0
for file in "${PATCH_FILES[@]}"; do
    if [ -f "$file" ]; then
        if grep -q "/home/" "$file" 2>/dev/null; then
            sed -i "s|/home/[^/]*|$USER_HOME|g" "$file"
            ok "$(basename "$file") → rutas actualizadas"
            ((PATCHED_COUNT++))
        else
            ok "$(basename "$file") (sin rutas fijas)"
        fi
    fi
done

if [ $PATCHED_COUNT -gt 0 ]; then
    ok "$PATCHED_COUNT archivo(s) con rutas actualizadas a: $USER_HOME"
fi

# ── Dependencias npm de ags ──────────────────────────────────────────
step "Instalando dependencias npm locales"

if [[ -f "$AGS_DEST/package.json" ]]; then
    cd "$AGS_DEST"
    npm install
    ok "Dependencias npm locales instaladas."
else
    warn "No se encontró package.json en $AGS_DEST — omitiendo npm install."
fi

# ── Crear directorio de música ───────────────────────────────────────
if [ ! -d "$USER_HOME/Música" ]; then
    info "Creando directorio de música..."
    mkdir -p "$USER_HOME/Música"
    ok "$USER_HOME/Música"
fi

# ── Permisos ─────────────────────────────────────────────────────────
step "Aplicando permisos"

find "$AGS_DEST" -name "*.sh" -exec chmod +x {} + 2>/dev/null || true
ok "Permisos aplicados."

# ── Resumen final ────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}${BOLD}║         Instalación completada exitosamente ✓       ║${RESET}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${BOLD}AGS config:${RESET}        $AGS_DEST"
echo -e "  ${BOLD}AUR helper:${RESET}        $AUR_HELPER"
echo -e "  ${BOLD}Comando AGS:${RESET}       ags run"
echo ""

if [ ${#AUX_CONFIGS[@]} -gt 0 ]; then
    echo -e "  ${CYAN}Configs replicadas automáticamente:${RESET}"
    for cfg in "${AUX_CONFIGS[@]}"; do
        if [ -d "$SCRIPT_DIR/$cfg" ]; then
            echo -e "    ${GREEN}•${RESET} $cfg"
        fi
    done
    if [ -d "$SCRIPT_DIR/mpd" ]; then
        echo -e "    ${GREEN}•${RESET} mpd"
    fi
    echo -e "    ${GREEN}•${RESET} ags"
    echo ""
fi

# ── Intervención manual requerida ────────────────────────────────────
echo -e "${YELLOW}${BOLD}⚠️  ACCIONES MANUALES RESTANTES:${RESET}"
echo ""

echo -e "${BOLD}1.${RESET} ${YELLOW}Configuración de Hyprland${RESET} (NO incluida en este script)"
echo "   Copia manualmente tu config de Hyprland desde tu backup:"
echo ""
echo -e "   ${BLUE}cp -r /ruta/de/tu/backup/hypr ~/.config/${RESET}"
echo ""
echo "   Verifica específicamente que incluyas:"
echo "     • hyprland.lua   → autostart con 'ags run'"
echo "     • keybinds.lua   → bind SUPER+D para 'ags request toggle-music'"
echo "     • rules.lua      → función toggle_ags_widget_anim()"
echo ""

echo -e "${BOLD}2.${RESET} ${YELLOW}Iniciar AGS${RESET}"
echo "   Reinicia sesión para que Hyprland ejecute AGS automáticamente,"
echo "   o inícialo manualmente:"
echo ""
echo -e "   ${BLUE}ags run${RESET}"
echo ""

echo -e "${BOLD}3.${RESET} ${YELLOW}Reaplicar cambios de código${RESET}"
echo "   Si modificas el código fuente, simplemente vuelve a ejecutar"
echo "   este script. Actualizará paquetes, configs y código:"
echo ""
echo -e "   ${BLUE}./$(basename "$0")${RESET}"
echo ""
