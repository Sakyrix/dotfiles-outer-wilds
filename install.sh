#!/usr/bin/env bash
set -e

echo "🛸 Déploiement du setup Outer Wilds..."

# 1. Installation des paquets requis
echo "📦 Installation des dépendances..."
sudo pacman -S --needed --noconfirm rofi starship fastfetch konsole qt6-multimedia ffmpegthumbs

# 2. Création des dossiers cibles
mkdir -p ~/.config/rofi ~/.config/fastfetch ~/.local/share/icons ~/.local/share/konsole ~/.local/share/wallpapers

# 3. Copie des ressources et configurations
echo "📂 Copie des fichiers..."
cp -r assets/icons/Outer-Wilds ~/.local/share/icons/ 2>/dev/null || true
cp -r assets/wallpapers/* ~/.local/share/wallpapers/ 2>/dev/null || true

cp -r configs/rofi/* ~/.config/rofi/ 2>/dev/null || true
cp -r configs/fastfetch/* ~/.config/fastfetch/ 2>/dev/null || true
cp configs/terminal/starship.toml ~/.config/
cp configs/terminal/bashrc ~/.bashrc
cp configs/terminal/'Profil 1.profile' ~/.local/share/konsole/ 2>/dev/null || true

# Layout KDE (Panneaux, barre de vie, couleurs, fenêtres)
cp configs/kde/plasma-org.kde.plasma.desktop-appletsrc ~/.config/ 2>/dev/null || true
cp configs/kde/kdeglobals ~/.config/ 2>/dev/null || true
cp configs/kde/kwinrc ~/.config/ 2>/dev/null || true
cp configs/kde/kscreenlockerrc ~/.config/ 2>/dev/null || true

# 4. Configuration SDDM (si présent)
if [ -d "configs/sddm" ]; then
    sudo mkdir -p /etc/sddm.conf.d
    sudo cp configs/sddm/theme.conf /etc/sddm.conf.d/ 2>/dev/null || true
    if [ -d "/usr/share/sddm/themes/sddm-astronaut-theme/Themes" ]; then
        sudo cp configs/sddm/astronaut.conf /usr/share/sddm/themes/sddm-astronaut-theme/Themes/ 2>/dev/null || true
    fi
fi

echo "✅ Fichiers installés ! Redémarre ta session KDE pour appliquer la disposition."