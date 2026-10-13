#!/usr/bin/env bash
set -e

echo "🛸 Installation complète du setup Outer Wilds..."

# 1. Installation des dépendances système
echo "📦 Installation des paquets officiels..."
sudo pacman -S --needed --noconfirm rofi starship fastfetch konsole

# 2. Création de l'arborescence
mkdir -p ~/.config/rofi ~/.config/fastfetch ~/.local/share/icons ~/.local/share/konsole

# 3. Copie des icônes et configurations
echo "📂 Déploiement des fichiers de configuration..."
cp -r assets/icons/Outer-Wilds ~/.local/share/icons/ 2>/dev/null || true
cp -r configs/rofi/* ~/.config/rofi/ 2>/dev/null || true
cp -r configs/fastfetch/* ~/.config/fastfetch/ 2>/dev/null || true
cp configs/terminal/starship.toml ~/.config/
cp configs/terminal/bashrc ~/.bashrc
cp configs/terminal/'Profil 1.profile' ~/.local/share/konsole/ 2>/dev/null || true
cp configs/kde/kscreenlockerrc ~/.config/

# 4. Activation automatique dans KDE Plasma
echo "🎨 Application des thèmes et réglages KDE..."

# Activer le thème de curseurs
if command -v plasma-apply-cursortheme &>/dev/null; then
    plasma-apply-cursortheme Outer-Wilds 2>/dev/null || true
fi

# Définir le profil Konsole par défaut
kwriteconfig6 --file konsolerc --group "Desktop Entry" --key DefaultProfile "Profil 1.profile" 2>/dev/null || \
kwriteconfig5 --file konsolerc --group "Desktop Entry" --key DefaultProfile "Profil 1.profile" 2>/dev/null || true

# 5. SDDM (Écran de connexion)
if [ -d "configs/sddm" ]; then
    echo "🔒 Application de la configuration SDDM..."
    sudo mkdir -p /etc/sddm.conf.d
    sudo cp configs/sddm/theme.conf /etc/sddm.conf.d/ 2>/dev/null || true
    
    # Si le thème sddm-astronaut est présent sur le système
    if [ -d "/usr/share/sddm/themes/sddm-astronaut-theme/Themes" ]; then
        sudo cp configs/sddm/astronaut.conf /usr/share/sddm/themes/sddm-astronaut-theme/Themes/ 2>/dev/null || true
    fi
fi

echo "✅ Tout est installé et configuré !"