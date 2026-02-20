#!/usr/bin/env bash
# ============================================================
#  install.sh — Instalador del tema SDDM "myGlass"
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
THEME_NAME="myGlass"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"   # directorio donde está este script
SDDM_THEMES_DIR="/usr/share/sddm/themes"
THEME_DEST="$SDDM_THEMES_DIR/$THEME_NAME"
SDDM_CONF_DIR="/etc/sddm.conf.d"
SDDM_THEME_CONF="$SDDM_CONF_DIR/theme.conf"

# ── Helpers ──────────────────────────────────────────────────
info()    { echo -e "${CYAN}${BOLD}[*]${RESET} $*"; }
success() { echo -e "${GREEN}${BOLD}[✓]${RESET} $*"; }
warning() { echo -e "${YELLOW}${BOLD}[!]${RESET} $*"; }
error()   { echo -e "${RED}${BOLD}[✗]${RESET} $*"; exit 1; }

confirm() {
    echo -e "${YELLOW}${BOLD}[?]${RESET} $* [s/N] "
    read -r ans
    [[ "$ans" =~ ^[sS]$ ]]
}

# ── Cabecera ─────────────────────────────────────────────────
echo ""
echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}${BOLD}║       Instalador — myGlass SDDM Theme    ║${RESET}"
echo -e "${CYAN}${BOLD}║         Arch Linux + Hyprland            ║${RESET}"
echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════╝${RESET}"
echo ""

# ── Verificar root ───────────────────────────────────────────
if [[ "$EUID" -ne 0 ]]; then
    error "Este script debe ejecutarse como root.\n  Usa: sudo bash install.sh"
fi

# ── Verificar que estamos en Arch Linux ──────────────────────
if ! command -v pacman &>/dev/null; then
    error "No se encontró pacman. ¿Estás en Arch Linux?"
fi

# ── 1. Instalar dependencias ─────────────────────────────────
info "Instalando dependencias de Qt5 y SDDM..."

PACKAGES=(
    sddm
    qt5-base
    qt5-declarative
    qt5-graphicaleffects
    qt5-multimedia
    qt5-quickcontrols2
    qt5-svg
    qt5-wayland
    gst-plugins-good
    gst-plugins-bad
    gst-libav
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
    pacman -S --noconfirm "${TO_INSTALL[@]}" || error "Falló la instalación de paquetes"
    success "Dependencias instaladas"
else
    success "Todas las dependencias ya estaban instaladas"
fi

# ── 2. Habilitar y configurar SDDM ───────────────────────────
info "Habilitando servicio SDDM..."

# Deshabilitar otros display managers si están activos
for dm in gdm lightdm ly; do
    if systemctl is-enabled "$dm" &>/dev/null; then
        warning "Deshabilitando $dm..."
        systemctl disable "$dm" 2>/dev/null || true
    fi
done

systemctl enable sddm 2>/dev/null && success "SDDM habilitado" || warning "SDDM ya estaba habilitado"

# ── 3. Crear directorio de configuración SDDM ────────────────
info "Configurando SDDM..."

mkdir -p "$SDDM_CONF_DIR"

if [[ -f "$SDDM_THEME_CONF" ]]; then
    warning "Ya existe $SDDM_THEME_CONF"
    # Verificar si ya tiene sección [Theme]
    if grep -q "^\[Theme\]" "$SDDM_THEME_CONF"; then
        # Actualizar Current= dentro de [Theme]
        if grep -q "^Current=" "$SDDM_THEME_CONF"; then
            sed -i "s/^Current=.*/Current=$THEME_NAME/" "$SDDM_THEME_CONF"
            success "Tema actualizado en $SDDM_THEME_CONF"
        else
            sed -i "/^\[Theme\]/a Current=$THEME_NAME" "$SDDM_THEME_CONF"
            success "Tema añadido en sección [Theme] existente"
        fi
    else
        # Añadir sección [Theme] al final
        echo "" >> "$SDDM_THEME_CONF"
        echo "[Theme]" >> "$SDDM_THEME_CONF"
        echo "Current=$THEME_NAME" >> "$SDDM_THEME_CONF"
        success "Sección [Theme] añadida a $SDDM_THEME_CONF"
    fi
else
    # Crear archivo de configuración desde cero
    cat > "$SDDM_THEME_CONF" << CONF
[Theme]
Current=$THEME_NAME
CONF
    success "Archivo $SDDM_THEME_CONF creado"
fi

# ── 4. Selección de animación de huella dactilar ─────────────
echo -e "\n${BOLD}[2/4] Instalando tema ${THEME_NAME}...${NC}"
echo -e ""
echo -e "  ${BOLD}¿Activar animación de huella dactilar al ingresar?${NC}"
echo -e "  ${CYAN}1)${NC} Sí — mostrar animación al presionar Enter"
echo -e "  ${CYAN}2)${NC} No — login directo sin animación"
echo -e ""
read -rp "  Selecciona [1/2]: " FP_CHOICE

case "$FP_CHOICE" in
    1)
        FINGERPRINT_ENABLED=true
        echo "[ok] Animación de huella: activada"
        ;;
    2)
        FINGERPRINT_ENABLED=false
        echo "[ok] Animación de huella: desactivada"
        ;;
    *)
        echo "[warn] Opción no válida, se usará Sin animación por defecto"
        FINGERPRINT_ENABLED=false
        ;;
esac


# ── 4. Instalar el tema ───────────────────────────────────────
info "Instalando tema $THEME_NAME en $SDDM_THEMES_DIR..."

mkdir -p "$SDDM_THEMES_DIR"


# Copiar todos los archivos del repositorio al destino
cp -r "$REPO_DIR/myGlass/" "$SDDM_THEMES_DIR/"
success "Tema copiado a $THEME_DEST"


# ── Parche LoginPanel.qml según elección de huella ───────────
LOGIN_PANEL="${THEME_DEST}/components/LoginPanel.qml"

if [ ! -f "$LOGIN_PANEL" ]; then
    warn "No se encontró components/LoginPanel.qml, saltando parche de huella"
else
    if [ "$FINGERPRINT_ENABLED" = false ]; then
        # Reemplazar el bloque onAccepted con versión sin animación
        sudo python3 - "$LOGIN_PANEL" << 'PYEOF'
import sys, re

path = sys.argv[1]
with open(path, 'r') as f:
    content = f.read()

# Reemplazar onAccepted con versión sin animación
old_accepted = (
    r'onAccepted:\s*\{'
    r'\s*loginButton\.clicked\(\)'
    r'\s*passwordField\.visible\s*=\s*false'
    r'\s*loginButton\.visible\s*=\s*false'
    r'\s*fingerprintIcon\.visible\s*=\s*true'
    r'\s*fingerprintIcon\.playing\s*=\s*true'
    r'\s*restoreTimer\.start\(\)'
    r'\s*\}'
)
new_accepted = (
    'onAccepted: {\n'
    '                loginButton.clicked()\n'
    '            }'
)

# Eliminar bloque Timer restoreTimer completo
old_timer = (
    r'\s*Timer\s*\{'
    r'\s*id:\s*restoreTimer'
    r'\s*interval:\s*\d+'
    r'\s*repeat:\s*false'
    r'\s*onTriggered:\s*\{'
    r'\s*passwordField\.visible\s*=\s*true'
    r'\s*loginButton\.visible\s*=\s*true'
    r'\s*fingerprintIcon\.visible\s*=\s*false'
    r'\s*fingerprintIcon\.playing\s*=\s*false'
    r'\s*\}'
    r'\s*\}'
)
result = re.sub(old_accepted, new_accepted, content, flags=re.MULTILINE)
result = re.sub(old_timer, "", result, flags=re.MULTILINE)

with open(path, 'w') as f:
    f.write(result)

print("  Parche aplicado: animación de huella desactivada")
PYEOF
        echo "[ok] LoginPanel.qml parcheado sin animación"
    else
        echo "[ok] LoginPanel.qml sin cambios (animación activada)"
    fi
fi

BG_DIR="$THEME_DEST/backgrounds"

# ── 5. Permisos ───────────────────────────────────────────────
info "Ajustando permisos..."
chmod -R 755 "$THEME_DEST"
find "$THEME_DEST" -type f -name "*.sh" -exec chmod +x {} \;
success "Permisos aplicados"


# ── Resumen final ─────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}${BOLD}║        Instalación completada ✓          ║${RESET}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${BOLD}Repositorio en ${RESET}  $REPO_DIR"
echo -e "  ${BOLD}Tema instalado en:${RESET}  $THEME_DEST"
echo -e "  ${BOLD}Configuración en:${RESET}   $SDDM_THEME_CONF"
echo ""
echo -e "  ${YELLOW}Para añadir fondos:${RESET}"
echo -e "    1. Copia tus imágenes/videos a:  $BG_DIR"
echo -e "    2. Ejecuta:  sudo bash $THEME_DEST/generate-index.sh"
echo ""
echo -e "  ${YELLOW}Para probar el tema sin reiniciar:${RESET}"
echo -e "    sddm-greeter-qt6 --test-mode --theme $THEME_DEST"
echo ""
echo -e "  ${YELLOW}Para aplicar los cambios:${RESET}"
echo -e "    sudo systemctl restart sddm"
echo ""
