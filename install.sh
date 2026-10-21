#!/usr/bin/env bash
set -e

echo "🛸 Déploiement du setup Outer Wilds..."
sudo pacman -S --needed --noconfirm base-devel git
git clone https://aur.archlinux.org/yay.git /tmp/yay
cd /tmp/yay && makepkg -si --noconfirm && cd ~
yay -S --noconfirm plasma6-wallpapers-smart-video-wallpaper-git

# 1. Dépendances système
sudo pacman -S --needed --noconfirm rofi starship fastfetch konsole qt6-multimedia ffmpegthumbs

# 2. Dossiers
mkdir -p ~/.config/rofi ~/.config/fastfetch ~/.local/share/icons ~/.local/share/konsole ~/.local/share/wallpapers

# 3. Copie des fichiers
cp -r assets/icons/Outer-Wilds ~/.local/share/icons/ 2>/dev/null || true
cp -r assets/wallpapers/* ~/.local/share/wallpapers/ 2>/dev/null || true

cp -r configs/rofi/* ~/.config/rofi/ 2>/dev/null || true
cp -r configs/fastfetch/* ~/.config/fastfetch/ 2>/dev/null || true
cp configs/terminal/starship.toml ~/.config/
cp configs/terminal/bashrc ~/.bashrc
cp configs/terminal/'Profil 1.profile' ~/.local/share/konsole/ 2>/dev/null || true

# Remplacement des chemins hardcodés vers le home de l'utilisateur courant
sed -i "s|/home/[^/]*|$HOME|g" configs/kde/plasma-org.kde.plasma.desktop-appletsrc 2>/dev/null || true

# Fermer Plasma temporairement pour réécrire le fichier de disposition sans qu'il soit écrasé
kquitapp6 plasmashell 2>/dev/null || true
sleep 1

cp configs/kde/plasma-org.kde.plasma.desktop-appletsrc ~/.config/ 2>/dev/null || true
cp configs/kde/kdeglobals ~/.config/ 2>/dev/null || true
cp configs/kde/kwinrc ~/.config/ 2>/dev/null || true

# Relancer Plasma
kstart plasmashell &>/dev/null &

# Appliquer le curseur
plasma-apply-cursortheme Outer-Wilds 2>/dev/null || true

echo "✅ Terminé ! Redémarre ta session."