<div align="center">
  <h1>🌌 Hyprland Dotfiles</h1>
  <p><em>A modern, aesthetic and fully dynamic Hyprland setup for Arch Linux</em></p>
</div>

---

## ✨ Main Features

### 🎨 Dynamic Theming
- **Pywal integration** — Colors are automatically extracted from your wallpaper and applied across the entire system (Hyprland borders, Rofi, Starship prompt, icon themes)
- **Wallpaper selector** — Supports static images (jpg, png, webp, gif) and video wallpapers (mp4, mkv, webm) via `mpvpaper` and `awww`
- **Glass/frosted aesthetic** — Transparent panels, blur effects, and rounded corners throughout

### 🖥️ Core Components
| Component | Tool |
|-----------|------|
| **Compositor** | Hyprland (Wayland) |
| **Shell** | Zsh + Oh My Zsh |
| **Prompt** | Starship |
| **Terminal** | Kitty |
| **Bar** | Waybar (HyDE-style) |
| **Launcher** | Rofi (wayland) |
| **File Manager** | Dolphin |
| **Widgets** | EWW (Control Panel + Music Player) |
| **Login Screen** | SDDM (myGlass theme) |
| **Audio Visualizer** | Cava |

### 🎛️ EWW Widgets
- **Control Panel** (`Super + A`) — WiFi, Bluetooth, brightness, volume sliders, quick launch shortcuts
- **Music Panel** (`Super + D`) — MPD player with album art, Cava visualizer, playback controls, music library browser

### ⚡ Keybindings
| Binding | Action |
|---------|--------|
| `Super + Q` | Open terminal |
| `Super + E` | Open file manager |
| `Super + R` | Open launcher |
| `Super + V` | Toggle floating |
| `Super + W` | Wallpaper selector |
| `Super + A` | Toggle control panel |
| `Super + D` | Toggle music panel |
| `Super + 1-0` | Switch workspaces |
| `Super + Scroll` | Cycle workspaces |

### 🎬 Animations
- Custom bezier curves (`wind`, `winIn`, `winOut`, `liner`)
- Smooth slide animations for windows, layers and workspaces
- Animated borders with looping angle rotation
- Fade effects on open/close

---

## 📋 Prerequisites

### System
- **Arch Linux** (recommended)
- **Wayland** session
- **Hyprland** installed

### Core Packages
```bash
pacman -S hyprland waybar rofi-wayland kitty dolphin sddm \
  mpd mpc networkmanager bluez bluez-utils brightnessctl \
  pipewire pipewire-pulse pipewire-alsa wireplumber \
  cava playerctl ffmpeg imagemagick jq python gawk grep \
  coreutils base-devel git
```

### Qt/KDE Theming
```bash
pacman -S kvantum qt6ct tela-circle-icon-theme-dracula \
  qt5-base qt5-declarative qt5-graphicaleffects qt5-multimedia \
  qt5-quickcontrols2 qt5-svg qt5-wayland
```

### AUR Packages
```bash
yay -S pywal mpvpaper awww eww-git
```

### AUR Helper
- `yay` or `paru` (scripts auto-install `yay` if not found)

---

## 🚀 Installation

Each component has its own installer script. Run them from the repository root:

```bash
# Wallpaper selector + dependencies
bash WallpaperSelector/install-selector.sh

# Rofi configuration
bash RofiMenu/install-rofi-menu.sh

# Zsh plugins
bash Zsh/install-plugins.sh

# EWW widgets + MPD setup
bash ewwConfig/install-eww-config.sh

# SDDM myGlass theme
bash sddmConfig/install.sh

# Dolphin + Kvantum + icon themes
bash dolphin/install-config.sh
```

> **Note:** Scripts are designed for Arch Linux. Adapt paths and package managers for other distributions.

---

## 📁 Structure

```
├── Hyprland/hypr/          # Hyprland configuration
├── waybarConfig/waybar/    # Waybar bar + modules
├── RofiMenu/rofi/          # Rofi launcher theme
├── ewwConfig/eww/          # EWW widgets
├── kitty/                  # Kitty terminal
├── Zsh/                    # Zsh shell + Starship
├── WallpaperSelector/      # Wallpaper manager script
├── dolphin/                # Dolphin file manager
├── sddmConfig/             # SDDM login theme
└── starship/               # Starship prompt config
```

---

## 🖼️ Screenshots

> *Add your screenshots here*

---

## 🙏 Credits

- Inspired by [HyDE (Hyprland Dotfiles Environment)](https://github.com/HyDE-Project/HyDE)
- [Hyprland](https://hyprland.org/)
- [pywal](https://github.com/dylanaraps/pywal)
- [EWW](https://github.com/elkowar/eww)

---

<div align="center">
  <p><em>Enjoy your new desktop environment ✨</em></p>
</div>
