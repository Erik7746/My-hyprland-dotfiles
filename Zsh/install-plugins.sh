#!/bin/bash

# Definir la ruta de los plugins (estándar para Oh My Zsh)
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

echo "Instalando plugins para ZSH..."

# 1. Clonar zsh-syntax-highlighting
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
    echo "✓ zsh-syntax-highlighting descargado."
else
    echo "○ zsh-syntax-highlighting ya existe."
fi

# 2. Clonar zsh-autosuggestions
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
    echo "✓ zsh-autosuggestions descargado."
else
    echo "○ zsh-autosuggestions ya existe."
fi

echo "--------------------------------------------------------"
echo "Para activar los plugins, edita tu archivo ~/.zshrc"
echo "Busca la línea 'plugins=(...)' y déjala así:"
echo "plugins=(git zsh-syntax-highlighting zsh-autosuggestions)"
echo "--------------------------------------------------------"
echo "Luego reinicia tu terminal o ejecuta: source ~/.zshrc"

