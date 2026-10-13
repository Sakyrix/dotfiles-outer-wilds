#!/usr/bin/env bash
set -e

echo "🛸 Installation des dotfiles Outer Wilds..."

# Création des dossiers cibles s'ils n'existent pas
mkdir -p ~/.config ~/.local/share/icons ~/.local/share/konsole

# Sauvegarde et copie des éléments utilisateur
echo "📦 Copie des icônes et configurations..."

cp -r assets/icons/Outer-Wilds ~/.local/share/icons/ 2>/dev/null || true

# Sauvegarde automatique des anciens dossiers s'ils existent
for cfg in rofi fastfetch; do
    if [ -d "$HOME/.config/$cfg" ] && [ ! -L "$HOME/.config/$cfg" ]; then
        echo "   -> Sauvegarde de $cfg vers $cfg.bak"
        mv "$HOME/.config/$cfg" "$HOME/.config/${cfg}.bak"
    fi
done

# Application des configurations
cp -r configs/rofi ~/.config/
mkdir -p ~/.config/fastfetch && cp -r configs/fastfetch/* ~/.config/fastfetch/ 2>/dev/null || true
cp configs/terminal/starship.toml ~/.config/
cp configs/terminal/'Profil 1.profile' ~/.local/share/konsole/ 2>/dev/null || true
cp configs/kde/kscreenlockerrc ~/.config/

echo "✅ Configurations utilisateur installées !"
echo ""
echo "⚠️ Note pour SDDM (écran de connexion) :"
echo "   Pour l'appliquer, lance manuellement :"
echo "   sudo cp configs/sddm/theme.conf /etc/sddm.conf.d/"
echo "   sudo cp configs/sddm/astronaut.conf /usr/share/sddm/themes/sddm-astronaut-theme/Themes/"
