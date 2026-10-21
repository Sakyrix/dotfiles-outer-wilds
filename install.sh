#!/usr/bin/env bash
# Déploiement du setup Outer Wilds (Arch Linux + KDE Plasma 6)
#
# Usage : ./install.sh [--with-sddm]
#   --with-sddm   installe aussi le thème de connexion SDDM (astronaut) — demande sudo
set -Eeuo pipefail
 
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$HOME/.dotfiles-backup/outer-wilds-$STAMP"
WITH_SDDM=0
HAS_PLASMA=0
TMP_DIR=""
 
info() { printf '\033[1;36m%s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[!] %s\033[0m\n' "$*" >&2; }
die()  { printf '\033[1;31m[x] %s\033[0m\n' "$*" >&2; exit 1; }
 
cleanup() {
    if [ -n "$TMP_DIR" ]; then
        rm -rf "$TMP_DIR"
    fi
}
trap cleanup EXIT
trap 'warn "Échec ligne $LINENO : $BASH_COMMAND"' ERR
 
usage() {
    sed -n '2,5p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}
 
for arg in "$@"; do
    case "$arg" in
        --with-sddm) WITH_SDDM=1 ;;
        -h|--help)   usage; exit 0 ;;
        *)           die "Option inconnue : $arg (voir --help)" ;;
    esac
done
 
echo "🛸 Déploiement du setup Outer Wilds..."
 
# --- 0. Vérifications ----------------------------------------------------
if [ "$EUID" -eq 0 ]; then
    die "Ne lance pas ce script avec sudo ! Exécute-le simplement avec : ./install.sh"
fi
command -v pacman >/dev/null 2>&1 || die "Ce script est prévu pour Arch Linux (pacman introuvable)."
command -v sudo   >/dev/null 2>&1 || die "sudo est requis."
[ -d "$REPO_DIR/configs" ] && [ -d "$REPO_DIR/assets" ] \
    || die "Dossiers configs/ et assets/ introuvables dans $REPO_DIR"
 
if command -v kquitapp6 >/dev/null 2>&1; then
    HAS_PLASMA=1
else
    warn "KDE Plasma 6 non détecté : les étapes KDE (panneau, fond vidéo, curseur) seront ignorées."
fi
 
TMP_DIR="$(mktemp -d)"
 
# --- Fonctions de déploiement -----------------------------------------------
# Copie un fichier en sauvegardant l'ancienne version (si elle diffère).
deploy_file() {   # deploy_file <source> <destination>
    local src="$1" dest="$2" rel
    [ -f "$src" ] || die "Fichier manquant dans le dépôt : $src"
    if [ -e "$dest" ] && cmp -s "$src" "$dest"; then
        return 0
    fi
    if [ -e "$dest" ]; then
        rel="${dest#"$HOME"/}"
        mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
        cp -a "$dest" "$BACKUP_DIR/$rel"
    fi
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
}
 
# Copie récursive. Les chemins relatifs passés en 3e argument et suivants ne sont
# pas écrasés s'ils existent déjà (données de l'utilisateur).
deploy_tree() {   # deploy_tree <dossier source> <dossier destination> [garder...]
    local src="$1" dest="$2" f rel keep
    shift 2
    [ -d "$src" ] || die "Dossier manquant dans le dépôt : $src"
    while IFS= read -r -d '' f; do
        rel="${f#"$src"/}"
        for keep in "$@"; do
            if [ "$rel" = "$keep" ] && [ -e "$dest/$rel" ]; then
                continue 2
            fi
        done
        deploy_file "$f" "$dest/$rel"
    done < <(find "$src" -type f -print0)
}
 
# Adapte les chemins /home/<utilisateur> d'un fichier KDE sans modifier le dépôt.
render_paths() {   # render_paths <source> <fichier de sortie>
    local src="$1" out="$2" home_esc
    home_esc="$(printf '%s' "$HOME" | sed 's/[&|\\]/\\&/g')"
    sed -e 's|/home/[^/]*/dotfiles-outer-wilds/assets/wallpapers/|@HOME@/.local/share/wallpapers/|g' \
        -e 's|/home/[^/]*/Images/lock_wallpaper\.jpg|@HOME@/.local/share/wallpapers/lockscreen.jpg|g' \
        -e 's|/home/[^/]*|@HOME@|g' \
        -e "s|@HOME@|$home_esc|g" \
        "$src" > "$out"
}
 
# --- 1. Paquets officiels ------------------------------------------------------
info "📦 Installation des dépendances système..."
sudo pacman -S --needed --noconfirm \
    base-devel git python \
    rofi starship fastfetch eza konsole \
    ttf-jetbrains-mono-nerd \
    qt6-multimedia qt6-multimedia-ffmpeg ffmpegthumbs
 
# --- 2. yay + plugin de fond d'écran vidéo (AUR) ------------------------------
if [ "$HAS_PLASMA" -eq 1 ]; then
    if ! command -v yay >/dev/null 2>&1; then
        info "📦 Installation de yay..."
        git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$TMP_DIR/yay-bin"
        (cd "$TMP_DIR/yay-bin" && makepkg -si)
    fi
 
    info "🎥 Installation du plugin de fond d'écran vidéo..."
    # Pas de --noconfirm : yay te laisse relire les PKGBUILD de l'AUR avant installation.
    yay -S --needed plasma6-wallpapers-smart-video-wallpaper-reborn \
        || warn "Plugin vidéo non installé : le fond d'écran animé ne s'affichera pas."
fi
 
# --- 3. Ressources et configurations --------------------------------------------
info "📂 Copie des fichiers de configuration..."
deploy_tree "$REPO_DIR/assets/icons/Outer-Wilds" "$HOME/.local/share/icons/Outer-Wilds"
deploy_tree "$REPO_DIR/assets/wallpapers"        "$HOME/.local/share/wallpapers"
 
# Rofi : on garde tes favoris et ton historique s'ils existent déjà
deploy_tree "$REPO_DIR/configs/rofi" "$HOME/.config/rofi" favoris.txt state.json stats.json
chmod +x "$HOME/.config/rofi/run.sh" "$HOME/.config/rofi/launcher.py"
 
deploy_tree "$REPO_DIR/configs/fastfetch" "$HOME/.config/fastfetch"
deploy_file "$REPO_DIR/configs/terminal/starship.toml"   "$HOME/.config/starship.toml"
deploy_file "$REPO_DIR/configs/terminal/bashrc"          "$HOME/.bashrc"
deploy_file "$REPO_DIR/configs/terminal/Profil 1.profile" "$HOME/.local/share/konsole/Profil 1.profile"
 
# --- 4. KDE Plasma -------------------------------------------------------------
if [ "$HAS_PLASMA" -eq 1 ]; then
    info "🪐 Application de la configuration KDE..."
 
    render_paths "$REPO_DIR/configs/kde/plasma-org.kde.plasma.desktop-appletsrc" "$TMP_DIR/appletsrc"
    # L'icône du menu d'applications n'est pas dans le dépôt : sans elle, on laisse l'icône par défaut.
    if [ ! -f "$HOME/.config/conky/hud/outerwilds_icon.png" ]; then
        sed -i '/^icon=.*outerwilds_icon\.png$/d' "$TMP_DIR/appletsrc"
    fi
    render_paths "$REPO_DIR/configs/kde/kscreenlockerrc" "$TMP_DIR/kscreenlockerrc"
 
    # plasmashell relit sa config au démarrage : on l'arrête avant d'écrire le panneau
    kquitapp6 plasmashell 2>/dev/null || true   # déjà arrêté = pas grave
    sleep 1
 
    deploy_file "$TMP_DIR/appletsrc"                  "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
    deploy_file "$TMP_DIR/kscreenlockerrc"            "$HOME/.config/kscreenlockerrc"
    deploy_file "$REPO_DIR/configs/kde/kdeglobals"    "$HOME/.config/kdeglobals"
    deploy_file "$REPO_DIR/configs/kde/kwinrc"        "$HOME/.config/kwinrc"
    deploy_file "$REPO_DIR/configs/kde/konsolerc"     "$HOME/.config/konsolerc"
 
    if command -v kstart >/dev/null 2>&1; then
        kstart plasmashell >/dev/null 2>&1 &
    else
        nohup plasmashell >/dev/null 2>&1 &
    fi
 
    if command -v qdbus6 >/dev/null 2>&1; then
        qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 \
            || warn "KWin n'a pas rechargé sa config : redémarre la session."
    fi
 
    plasma-apply-cursortheme Outer-Wilds >/dev/null 2>&1 \
        || warn "Curseur non appliqué : choisis « Outer-Wilds » dans Paramètres système → Curseurs."
fi
 
# --- 5. Thème SDDM (optionnel) ---------------------------------------------------
if [ "$WITH_SDDM" -eq 1 ]; then
    info "🔐 Installation du thème de connexion SDDM..."
    theme_dir=/usr/share/sddm/themes/sddm-astronaut-theme
 
    sudo pacman -S --needed --noconfirm sddm qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg
    if [ ! -d "$theme_dir" ]; then
        sudo git clone -b master --depth 1 \
            https://github.com/keyitdev/sddm-astronaut-theme.git "$theme_dir"
    fi
    if [ -d "$theme_dir/Fonts" ]; then
        sudo cp -r "$theme_dir"/Fonts/* /usr/share/fonts/
        sudo fc-cache -f
    fi
 
    # Sauvegarde unique de la config d'origine du thème
    if [ -f "$theme_dir/Themes/astronaut.conf" ] && [ ! -f "$theme_dir/Themes/astronaut.conf.orig" ]; then
        sudo cp "$theme_dir/Themes/astronaut.conf" "$theme_dir/Themes/astronaut.conf.orig"
    fi
    sudo install -Dm644 "$REPO_DIR/configs/sddm/astronaut.conf" "$theme_dir/Themes/astronaut.conf"
    # astronaut.conf pointe vers ce chemin pour l'image de fond
    sudo install -Dm644 "$REPO_DIR/assets/wallpapers/sddm-campfire.png" \
        /usr/share/wallpapers/outer-wilds/background.png
    sudo sed -i 's|^ConfigFile=.*|ConfigFile=Themes/astronaut.conf|' "$theme_dir/metadata.desktop"
 
    if [ -f /etc/sddm.conf.d/theme.conf ] && ! cmp -s "$REPO_DIR/configs/sddm/theme.conf" /etc/sddm.conf.d/theme.conf; then
        sudo cp /etc/sddm.conf.d/theme.conf "/etc/sddm.conf.d/theme.conf.bak-$STAMP"
    fi
    sudo install -Dm644 "$REPO_DIR/configs/sddm/theme.conf" /etc/sddm.conf.d/theme.conf
    echo "   Aperçu sans te déconnecter : sddm-greeter-qt6 --test-mode --theme $theme_dir"
fi
 
# --- Fin -------------------------------------------------------------------------
echo
echo "✅ Terminé ! Redémarre ta session."
if [ -d "$BACKUP_DIR" ]; then
    echo "💾 Anciennes configs sauvegardées dans : $BACKUP_DIR"
fi
echo "ℹ️  À faire à la main (voir configs/rofi/README.md) : raccourci global Meta+Espace → ~/.config/rofi/run.sh,"
echo "   et règle KWin de flou d'arrière-plan pour la fenêtre « rofi »."
 