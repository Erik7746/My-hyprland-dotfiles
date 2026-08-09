#!/bin/bash
set -e

# ═══════════════════════════════════════════════════════════════════
#  Instalador de entorno AGS completo
#  Requisito: colocar este script junto a las carpetas de config:
#             ags/ dunst/ mpd/ mpDris2/ mpc/ 
#  Excepción: NO copia hypr/ (debe configurarse manualmente)
# ═══════════════════════════════════════════════════════════════════

# ── Colores ──
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ── Rutas ──
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_HOME="$HOME"
CONFIG_HOME="$HOME/.config"

# ── Validación: la carpeta ags debe existir junto al script ──
if [ ! -d "$SCRIPT_DIR/ags" ]; then
    echo -e "${RED}Error: No se encontró la carpeta 'ags' junto al script.${NC}"
    echo "   Ubicación esperada: $SCRIPT_DIR/ags"
    echo "   Asegúrate de colocar este script en el mismo directorio"
    echo "   que las carpetas de configuración (ags, dunst, mpd, etc.)."
    exit 1
fi

# ── Verificar herramientas del sistema ──
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  Instalador de entorno AGS completo${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${YELLOW}→ Verificando dependencias del sistema...${NC}"

MISSING_PKGS=()
for pkg in ags npm gjs; do
    if ! command -v "$pkg" &> /dev/null; then
        MISSING_PKGS+=("$pkg")
    fi
done

if [ ${#MISSING_PKGS[@]} -ne 0 ]; then
    echo -e "${RED}  ✗ Faltan herramientas esenciales:${NC} ${MISSING_PKGS[*]}"
    echo ""
    echo "   Instálalas antes de continuar:"
    echo ""
    echo -e "   ${BLUE}sudo pacman -S ags gtk4-layer-shell gjs npm${NC}"
    echo ""
    exit 1
else
    echo -e "  ${GREEN}✓${NC} ags, npm y gjs están disponibles"
fi

# ── Función: sincronizar directorio genérico ──
sync_config_dir() {
    local name="$1"
    local src="$SCRIPT_DIR/$name"
    local dest="$CONFIG_HOME/$name"

    if [ ! -d "$src" ]; then
        return 0
    fi

    echo ""
    echo -e "${YELLOW}→ Replicando $name...${NC}"
    mkdir -p "$dest"

    if command -v rsync &> /dev/null; then
        rsync -a --delete \
            --exclude='.git' \
            --exclude='node_modules' \
            "$src/" "$dest/"
    else
        # Fallback sin rsync
        find "$dest" -mindepth 1 -not -path "$dest/node_modules/*" -not -path "$dest/node_modules" -delete 2>/dev/null || true
        cp -r "$src"/* "$dest/" 2>/dev/null || true
        rm -rf "$dest/.git"
    fi

    echo -e "  ${GREEN}✓${NC} $name → $dest"
}

# ── Replicar configs auxiliares ──
# Lista de directorios que se copiarán automáticamente si existen
AUX_CONFIGS=(dunst mpDris2 mpc)

for cfg in "${AUX_CONFIGS[@]}"; do
    sync_config_dir "$cfg"
done

# ── Replicar mpd (excluir archivos de runtime) ──
if [ -d "$SCRIPT_DIR/mpd" ]; then
    echo ""
    echo -e "${YELLOW}→ Replicando mpd (sin archivos de runtime)...${NC}"
    mkdir -p "$CONFIG_HOME/mpd"

    if command -v rsync &> /dev/null; then
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

    echo -e "  ${GREEN}✓${NC} mpd → $CONFIG_HOME/mpd"
fi

# ── Replicar ags (manejo especial) ──
AGS_SRC="$SCRIPT_DIR/ags"
AGS_DEST="$CONFIG_HOME/ags"

echo ""
echo -e "${YELLOW}→ Replicando ags...${NC}"

mkdir -p "$AGS_DEST"

if command -v rsync &> /dev/null; then
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

echo -e "  ${GREEN}✓${NC} Archivos copiados (node_modules preservado si existía)"

# ── Hardcodear rutas del usuario ──
echo ""
echo -e "${YELLOW}→ Ajustando rutas hardcodeadas...${NC}"

PATCH_FILES=(
    "$AGS_DEST/lib/music.ts"
)

PATCHED_COUNT=0
for file in "${PATCH_FILES[@]}"; do
    if [ -f "$file" ]; then
        if grep -q "/home/" "$file" 2>/dev/null; then
            sed -i "s|/home/[^/]*|$USER_HOME|g" "$file"
            echo -e "  ${GREEN}✓${NC} $(basename "$file") → rutas actualizadas"
            ((PATCHED_COUNT++))
        else
            echo -e "  ${GREEN}✓${NC} $(basename "$file") (sin rutas fijas)"
        fi
    fi
done

if [ $PATCHED_COUNT -gt 0 ]; then
    echo -e "  ${GREEN}✓${NC} $PATCHED_COUNT archivo(s) con rutas actualizadas a: $USER_HOME"
fi

# ── Instalar dependencias npm de ags ──
echo ""
echo -e "${YELLOW}→ Instalando dependencias npm de ags...${NC}"

cd "$AGS_DEST"

if [ -f "package.json" ]; then
    npm install
    echo -e "  ${GREEN}✓${NC} Dependencias listas"
else
    echo -e "${RED}  ✗ No se encontró package.json en $AGS_DEST${NC}"
    exit 1
fi

# ── Crear directorio de música si no existe ──
if [ ! -d "$USER_HOME/Música" ]; then
    echo ""
    echo -e "${YELLOW}→ Creando directorio de música...${NC}"
    mkdir -p "$USER_HOME/Música"
    echo -e "  ${GREEN}✓${NC} $USER_HOME/Música"
fi

# ── Resumen ──
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Instalación completada exitosamente${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  Configuración AGS:     ${BLUE}$AGS_DEST${NC}"
echo -e "  Comando para iniciar:  ${BLUE}ags run${NC}"
echo ""
echo -e "  ${CYAN}Configs replicadas automáticamente:${NC}"
for cfg in "${AUX_CONFIGS[@]}"; do
    if [ -d "$SCRIPT_DIR/$cfg" ]; then
        echo -e "    ${GREEN}•${NC} $cfg"
    fi
done
if [ -d "$SCRIPT_DIR/mpd" ]; then
    echo -e "    ${GREEN}•${NC} mpd"
fi
echo -e "    ${GREEN}•${NC} ags"
echo ""

# ── Intervención manual requerida ──
echo -e "${YELLOW}⚠️  ACCIONES MANUALES RESTANTES:${NC}"
echo ""

echo "1. ${YELLOW}Paquetes del sistema${NC}"
echo "   Instala los paquetes necesarios (algunos pueden faltar):"
echo ""
echo -e "   ${BLUE}sudo pacman -S \\"
echo "     ags gtk4-layer-shell gjs \\"
echo "     networkmanager bluez bluez-utils \\"
echo "     pipewire pipewire-pulse wireplumber \\"
echo "     brightnessctl \\"
echo "     mpd mpc mpdris2 \\"
echo "     ffmpeg cava \\"
echo "     dunst waybar \\"
echo "     kitty dolphin rofi \\"
echo "     xdg-desktop-portal-hyprland${NC}"
echo ""

echo "2. ${YELLOW}Servicios del sistema${NC}"
echo "   Activa e inicia los servicios esenciales:"
echo ""
echo -e "   ${BLUE}sudo systemctl enable --now NetworkManager bluetooth${NC}"
echo -e "   ${BLUE}systemctl --user enable --now pipewire pipewire-pulse wireplumber${NC}"
echo -e "   ${BLUE}systemctl --user enable --now mpd${NC}"
echo ""

echo "3. ${YELLOW}Configuración de Hyprland${NC} (NO incluida en este script)"
echo "   Copia manualmente tu config de Hyprland desde tu backup:"
echo ""
echo -e "   ${BLUE}cp -r /ruta/de/tu/backup/hypr ~/.config/${NC}"
echo ""
echo "   Verifica específicamente que incluyas:"
echo "     • hyprland.lua   → autostart con 'ags run'"
echo "     • keybinds.lua   → bind SUPER+D para 'toggle-music'"
echo "     • rules.lua      → función toggle_ags_widget_anim()"
echo ""

echo "4. ${YELLOW}Iniciar AGS${NC}"
echo "   Reinicia sesión para que Hyprland lance AGS automáticamente,"
echo "   o ejecútalo manualmente:"
echo ""
echo -e "   ${BLUE}ags run${NC}"
echo ""

echo "5. ${YELLOW}Reaplicar cambios de código${NC}"
echo "   Si modificas el código fuente, simplemente vuelve a ejecutar"
echo "   este script desde el mismo directorio. Actualizará todo:"
echo ""
echo -e "   ${BLUE}./$(basename "$0")${NC}"
echo ""
