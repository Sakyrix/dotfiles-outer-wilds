#!/usr/bin/env bash
set -e

echo "🛸 Déploiement du setup Outer Wilds..."

# 1. Empêcher de lancer le script directement avec sudo
if [ "$EUID" -eq 0 ]; then
  echo "❌ Ne lance pas ce script avec sudo ! Exécute-le simplement avec : ./install.sh"
  exit 1
fi

# 2. Installation des paquets officiels Arch
echo "📦 Installation des dépendances système..."
sudo pacman -S --needed --noconfirm base-devel git rofi starship fastfetch konsole qt6-multimedia ffmpegthumbs

# 3. Installation de yay si absent
if ! command -v yay &>/dev/null; then
    echo "📦 Installation de yay..."
    rm -rf /tmp/yay
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    (cd /tmp/yay && makepkg -si --noconfirm)
    rm -rf /tmp/yay
fi

# 4. Installation du plugin vidéo AUR (avec nom corrigé + sécurité)
echo "🎥 Installation du plugin vidéo..."
yay -S --needed --noconfirm smart-video-wallpaper-git 2>/dev/null || true

# 5. Création des dossiers cibles
mkdir -p ~/.config/rofi ~/.config/fastfetch ~/.local/share/icons ~/.local/share/konsole ~/.local/share/wallpapers

# 6. Copie des ressources et configurations
echo "📂 Copie des fichiers de configuration..."
cp -r assets/icons/Outer-Wilds ~/.local/share/icons/ 2>/dev/null || true
cp -r assets/wallpapers/* ~/.local/share/wallpapers/ 2>/dev/null || true

cp -r configs/rofi/* ~/.config/rofi/ 2>/dev/null || true
cp -r configs/fastfetch/* ~/.config/fastfetch/ 2>/dev/null || true
cp configs/terminal/starship.toml ~/.config/ 2>/dev/null || true
cp configs/terminal/bashrc ~/.bashrc 2>/dev/null || true
cp configs/terminal/'Profil 1.profile' ~/.local/share/konsole/ 2>/dev/null || true

# Adaptation dynamique des chemins
sed -i "s|/home/[^/]*|$HOME|g" configs/kde/plasma-org.kde.plasma.desktop-appletsrc 2>/dev/null || true

# Réécriture propre du panneau KDE
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