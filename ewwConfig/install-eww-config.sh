#!/usr/bin/env bash
# =============================================================================
#  install-eww-config.sh — Instalador de configuración eww 
# =============================================================================

set -euo pipefail

# ── Colores ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Helpers ───────────────────────────────────────────────────────────────────
info()    { echo -e "${BLUE}${BOLD}[INFO]${RESET}  $*"; }
ok()      { echo -e "${GREEN}${BOLD}[ OK ]${RESET}  $*"; }
warn()    { echo -e "${YELLOW}${BOLD}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}${BOLD}[ERR ]${RESET}  $*" >&2; }
step()    { echo -e "\n${CYAN}${BOLD}══ $* ══${RESET}"; }
ask()     { echo -en "${YELLOW}${BOLD}[ ?? ]${RESET}  $* "; }

# ── Comprobaciones iniciales ──────────────────────────────────────────────────
step "Comprobaciones previas"

if [[ $EUID -eq 0 ]]; then
    error "No ejecutes este script como root. Se pedirá sudo cuando sea necesario."
    exit 1
fi

if ! command -v pacman &>/dev/null; then
    error "Este script es exclusivo para Arch Linux (pacman no encontrado)."
    exit 1
fi

ok "Usuario: $(whoami) | Sistema: Arch Linux detectado"

# ── AUR helper ────────────────────────────────────────────────────────────────
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

    # Instalar dependencias de compilación
    sudo pacman -S --needed --noconfirm base-devel git

    TMPDIR_YAY=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$TMPDIR_YAY/yay"
    (cd "$TMPDIR_YAY/yay" && makepkg -si --noconfirm)
    rm -rf "$TMPDIR_YAY"

    AUR_HELPER="yay"
    ok "yay instalado correctamente."
fi

# ── Paquetes oficiales ────────────────────────────────────────────────────────
step "Instalando paquetes de repositorios oficiales"

OFFICIAL_PKGS=(
    mpd
    mpc
    networkmanager
    bluez
    bluez-utils
    brightnessctl
    ffmpeg
    imagemagick
    python
    gawk
    grep
    cava
    coreutils
    base-devel
    git

)

info "Paquetes: ${OFFICIAL_PKGS[*]}"
sudo pacman -S --needed --noconfirm "${OFFICIAL_PKGS[@]}"
ok "Paquetes oficiales instalados."

# ── Paquetes AUR ──────────────────────────────────────────────────────────────
step "Instalando paquetes desde AUR"

AUR_PKGS=(
    eww-wayland
)

info "Paquetes AUR: ${AUR_PKGS[*]}"
"$AUR_HELPER" -S --needed --noconfirm "${AUR_PKGS[@]}"
ok "Paquetes AUR instalados."

# ── PipeWire / Audio ──────────────────────────────────────────────────────────
step "Configurando audio (PipeWire)"

PIPEWIRE_PKGS=(pipewire pipewire-pulse pipewire-alsa wireplumber)
MISSING_PW=()

for pkg in "${PIPEWIRE_PKGS[@]}"; do
    if ! pacman -Q "$pkg" &>/dev/null; then
        MISSING_PW+=("$pkg")
    fi
done

if [[ ${#MISSING_PW[@]} -gt 0 ]]; then
    ask "PipeWire no está completamente instalado. ¿Instalar ahora? [S/n]"
    read -r resp
    if [[ "$resp" =~ ^[Nn]$ ]]; then
        warn "Omitiendo PipeWire. Asegúrate de tener PulseAudio activo manualmente."
    else
        sudo pacman -S --needed --noconfirm "${PIPEWIRE_PKGS[@]}"
        systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true
        ok "PipeWire configurado."
    fi
else
    ok "PipeWire ya está instalado."
fi

# ── Directorio de música ───────────────────────────────────────────────────────
step "Configurando directorio de música"

DEFAULT_MUSIC_DIR="$HOME/musicas"
ask "Directorio de música [${DEFAULT_MUSIC_DIR}]: "
read -r MUSIC_DIR_INPUT
MUSIC_DIR="${MUSIC_DIR_INPUT:-$DEFAULT_MUSIC_DIR}"

if [[ ! -d "$MUSIC_DIR" ]]; then
    info "Creando directorio de música: $MUSIC_DIR"
    mkdir -p "$MUSIC_DIR"
fi
ok "Directorio de música: $MUSIC_DIR"

# ── Configuración de MPD ──────────────────────────────────────────────────────
step "Generando configuración de MPD"

MPD_DIR="$HOME/.config/mpd"
MPD_CONF="$MPD_DIR/mpd.conf"
MPD_DATA="$HOME/.local/share/mpd"

mkdir -p "$MPD_DIR" "$MPD_DATA/playlists"

if [[ -f "$MPD_CONF" ]]; then
    warn "Ya existe $MPD_CONF — creando backup en ${MPD_CONF}.bak"
    cp "$MPD_CONF" "${MPD_CONF}.bak"
fi

cat > "$MPD_CONF" <<EOF
# ── mpd.conf — generado por install-eww-config.sh ──────────────────────────

music_directory     "$MUSIC_DIR"
playlist_directory  "$MPD_DATA/playlists"
db_file             "$MPD_DATA/database"
log_file            "$MPD_DATA/log"
pid_file            "$MPD_DATA/pid"
state_file          "$MPD_DATA/state"
sticker_database    "$MPD_DATA/sticker.sql"

# Escuchar sólo localmente
bind_to_address     "127.0.0.1"
port                "6600"

# Salida de audio (PipeWire / PulseAudio)
audio_output {
    type    "pipewire"
    name    "PipeWire Output"
}

# Fallback PulseAudio
# audio_output {
#     type    "pulse"
#     name    "PulseAudio Output"
# }

auto_update         "yes"
EOF

ok "mpd.conf generado en $MPD_CONF"

# ── Servicios del sistema ─────────────────────────────────────────────────────
step "Habilitando y arrancando servicios"

# MPD (usuario)
info "Habilitando MPD (usuario)..."
systemctl --user enable --now mpd 2>/dev/null \
    && ok "MPD activo." \
    || warn "No se pudo iniciar MPD. Lánzalo manualmente: systemctl --user start mpd"

# NetworkManager (sistema)
if ! systemctl is-active --quiet NetworkManager; then
    info "Habilitando NetworkManager..."
    sudo systemctl enable --now NetworkManager \
        && ok "NetworkManager activo." \
        || warn "Revisa NetworkManager manualmente."
else
    ok "NetworkManager ya está activo."
fi

# Bluetooth
if ! systemctl is-active --quiet bluetooth; then
    info "Habilitando Bluetooth..."
    sudo systemctl enable --now bluetooth \
        && ok "Bluetooth activo." \
        || warn "Revisa bluetooth manualmente."
else
    ok "Bluetooth ya está activo."
fi

# ── Configuración de eww ──────────────────────────────────────────────────────
step "Instalando configuración de eww"

EWW_DIR="$HOME/.config/eww"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"


if [[ -d "$SCRIPT_DIR/../eww" ]]; then
    info "Copiando configuración desde $SCRIPT_DIR/../eww → $EWW_DIR"
    cp -r "$SCRIPT_DIR/../eww" "$EWW_DIR"
elif [[ -d "$SCRIPT_DIR/eww" ]]; then
    info "Copiando configuración desde $SCRIPT_DIR/eww → $EWW_DIR"
    cp -r "$SCRIPT_DIR/eww" "$EWW_DIR"
else
    warn "No se encontró la carpeta 'eww/' junto al script."
    warn "Copia manualmente tu configuración en: $EWW_DIR"
    mkdir -p "$EWW_DIR/scripts"
fi

# Asegurar permisos de ejecución en scripts
if [[ -d "$EWW_DIR/scripts" ]]; then
    chmod +x "$EWW_DIR/scripts/"*.sh 2>/dev/null || true
    ok "Permisos de ejecución aplicados a $EWW_DIR/scripts/"
fi

ok "Configuración de eww instalada en $EWW_DIR"

# ── Variable de entorno opcional ──────────────────────────────────────────────
step "Variables de entorno"

SHELL_RC=""
if [[ -f "$HOME/.zshrc" ]]; then
    SHELL_RC="$HOME/.zshrc"
elif [[ -f "$HOME/.bashrc" ]]; then
    SHELL_RC="$HOME/.bashrc"
fi

if [[ -n "$SHELL_RC" ]]; then
    if ! grep -q "MPD_MUSIC_DIR" "$SHELL_RC"; then
        echo "" >> "$SHELL_RC"
        echo "# eww music player" >> "$SHELL_RC"
        echo "export MPD_MUSIC_DIR=\"$MUSIC_DIR\"" >> "$SHELL_RC"
        ok "MPD_MUSIC_DIR añadida a $SHELL_RC"
    else
        warn "MPD_MUSIC_DIR ya existe en $SHELL_RC — no se modificó."
    fi
else
    warn "No se detectó ~/.zshrc ni ~/.bashrc. Añade manualmente:"
    echo "    export MPD_MUSIC_DIR=\"$MUSIC_DIR\""
fi

# ── Indexar biblioteca de música ──────────────────────────────────────────────
step "Indexando biblioteca de MPD"

if mpc update &>/dev/null; then
    ok "Biblioteca de MPD actualizada."
else
    warn "No se pudo actualizar la biblioteca de MPD. Hazlo manualmente con: mpc update"
fi

# ── Resumen final ─────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}${BOLD}║          Instalación completada con éxito            ║${RESET}"
echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${BOLD}eww config:${RESET}     $EWW_DIR"
echo -e "  ${BOLD}MPD config:${RESET}     $MPD_CONF"
echo -e "  ${BOLD}Música:${RESET}         $MUSIC_DIR"
echo -e "  ${BOLD}AUR helper:${RESET}     $AUR_HELPER"
echo ""
echo -e "  ${YELLOW}Próximos pasos:${RESET}"
echo -e "  1. Reinicia la sesión o ejecuta:  ${BOLD}source $SHELL_RC${RESET}"
echo -e "  2. Añade música a:                ${BOLD}$MUSIC_DIR${RESET}"
echo -e "  3. Indexa con:                    ${BOLD}mpc update${RESET}"
echo -e "  4. Lanza eww con:                 ${BOLD}eww open <nombre-widget>${RESET}"
echo ""
