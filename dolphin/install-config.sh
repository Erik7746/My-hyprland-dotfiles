#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAYAN_THEME="Layan"

echo "==> Instalando dependencias desde pacman..."
PACKAGES=("kvantum" "qt6ct")
for pkg in "${PACKAGES[@]}"; do
    if ! pacman -Qi "$pkg" &>/dev/null; then
        echo "  -> Instalando $pkg..."
        sudo pacman -S --noconfirm "$pkg"
    else
        echo "  -> $pkg ya está instalado."
    fi
done

echo ""
echo "==> Copiando tema Layan a /usr/share/Kvantum/..."
if [ -d "$SCRIPT_DIR/TemaKvantum/$LAYAN_THEME" ]; then
    sudo cp -r "$SCRIPT_DIR/TemaKvantum/$LAYAN_THEME" "/usr/share/Kvantum/"
    echo "  -> Tema Layan copiado correctamente."
else
    echo "  [ERROR] No se encontró la carpeta '$LAYAN_THEME' en el directorio del script: $SCRIPT_DIR"
    exit 1
fi

echo ""
echo "==> Aplicando tema Layan en Kvantum..."
mkdir -p "$HOME/.config/Kvantum"
cat > "$HOME/.config/Kvantum/kvantum.kvconfig" <<EOF
[General]
theme=$LAYAN_THEME
EOF
echo "  -> Tema Layan configurado en Kvantum."

echo ""
echo "==> Instalando tela-circle-icon-theme-dracula desde pacman..."
if ! pacman -Qi "tela-circle-icon-theme-dracula" &>/dev/null; then
    sudo pacman -S --noconfirm tela-circle-icon-theme-dracula
else
    echo "  -> tela-circle-icon-theme-dracula ya está instalado."
fi

echo ""
echo "==> Copiando temas de iconos a ~/.local/share/icons/..."
mkdir -p "$HOME/.local/share/icons"

for variant in "Tela-circle-dracula-dark" "Tela-circle-dracula" "Tela-circle-dracula-light"; do
    if [ -d "/usr/share/icons/$variant" ]; then
        cp -r "/usr/share/icons/$variant" "$HOME/.local/share/icons/"
        echo "  -> $variant copiado."
    else
        echo "  [AVISO] /usr/share/icons/$variant no encontrado, omitiendo."
    fi
done

echo ""
echo "==> Configurando qt6ct con el tema de iconos Tela-circle-dracula-dark..."
mkdir -p "$HOME/.config/qt6ct"
QT6CT_CONF="$HOME/.config/qt6ct/qt6ct.conf"

if [ -f "$QT6CT_CONF" ]; then
    # Si ya existe el archivo, actualizar/agregar la clave icon_theme en la sección [Appearance]
    if grep -q "^\[Appearance\]" "$QT6CT_CONF"; then
        # Sección existe: reemplazar o insertar icon_theme
        if grep -q "^icon_theme=" "$QT6CT_CONF"; then
            sed -i 's/^icon_theme=.*/icon_theme=Tela-circle-dracula-dark/' "$QT6CT_CONF"
        else
            sed -i '/^\[Appearance\]/a icon_theme=Tela-circle-dracula-dark' "$QT6CT_CONF"
        fi
    else
        echo "" >> "$QT6CT_CONF"
        echo "[Appearance]" >> "$QT6CT_CONF"
        echo "icon_theme=Tela-circle-dracula-dark" >> "$QT6CT_CONF"
    fi
else
    cat > "$QT6CT_CONF" <<EOF
[Appearance]
icon_theme=Tela-circle-dracula-dark
style=kvantum
EOF
fi
echo "  -> qt6ct configurado."

echo ""
echo "==> Modificando ~/.config/kdeglobals con el tema de iconos..."
KDEGLOBALS="$HOME/.config/kdeglobals"
mkdir -p "$HOME/.config"

if [ -f "$KDEGLOBALS" ]; then
    if grep -q "^\[Icons\]" "$KDEGLOBALS"; then
        if grep -q "^Theme=" "$KDEGLOBALS"; then
            sed -i 's/^Theme=.*/Theme=Tela-circle-dracula-dark/' "$KDEGLOBALS"
        else
            sed -i '/^\[Icons\]/a Theme=Tela-circle-dracula-dark' "$KDEGLOBALS"
        fi
    else
        echo "" >> "$KDEGLOBALS"
        printf "[Icons]\nTheme=Tela-circle-dracula-dark\n" >> "$KDEGLOBALS"
    fi
else
    printf "[Icons]\nTheme=Tela-circle-dracula-dark\n" > "$KDEGLOBALS"
fi
echo "  -> kdeglobals actualizado."

if [ -d "$HOME/.config/WallpaperSelector" ]; then
    echo "El directorio WallpaperSelector existe"
    cp -r "$SCRIPT_DIR/tela-recolor.sh" "$HOME/.config/WallpaperSelector/"
    echo "Se agrego los colores dinamicos"
fi
cp -r "$SCRIPT_DIR/dolphinrc" "$HOME/.config/"

echo ""
echo "✔ Instalación completada."
echo ""
echo "  Recuerda exportar las variables de entorno en tu hyprland.conf o en /etc/environment si aún no lo has hecho:"
echo "    env = QT_QPA_PLATFORMTHEME,qt6ct"
echo "    env = QT_STYLE_OVERRIDE,kvantum"
