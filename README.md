# dotfiles-outer-wilds 🛸

Setup Arch Linux + KDE Plasma 6 inspiré d'Outer Wilds : fond d'écran vidéo,
curseurs, lanceur Rofi « Onduloscope », prompt Starship, bannière Fastfetch.

## Installation

```bash
git clone https://github.com/Sakyrix/dotfiles-outer-wilds
cd dotfiles-outer-wilds
./install.sh              # setup complet
./install.sh --with-sddm  # + thème de connexion SDDM (demande sudo)
```

Ne lance pas le script avec `sudo`. Il demandera le mot de passe quand c'est
nécessaire. Il peut être relancé sans risque : les fichiers identiques sont
ignorés, et ce qui est écrasé est sauvegardé dans
`~/.dotfiles-backup/outer-wilds-<date>/`.

## Ce qui est installé

| Source | Destination | Rôle |
|---|---|---|
| paquets pacman | système | `rofi` `starship` `fastfetch` `eza` `konsole` `python` `ttf-jetbrains-mono-nerd` `qt6-multimedia` `qt6-multimedia-ffmpeg` `ffmpegthumbs` |
| AUR | système | `yay-bin` (si absent), `plasma6-wallpapers-smart-video-wallpaper-reborn` |
| `assets/icons/Outer-Wilds` | `~/.local/share/icons/` | thème de curseurs |
| `assets/wallpapers/` | `~/.local/share/wallpapers/` | vidéo HUD, écran de verrouillage |
| `configs/rofi/` | `~/.config/rofi/` | lanceur d'applications (tes favoris et historique sont conservés) |
| `configs/fastfetch/` | `~/.config/fastfetch/` | logo ASCII |
| `configs/terminal/` | `~/.bashrc`, `~/.config/starship.toml`, profil Konsole | terminal |
| `configs/kde/` | `~/.config/` | couleurs, KWin (3 bureaux, tiling), panneau Plasma, écran de verrouillage |
| `configs/sddm/` + `sddm-campfire.png` | `/usr/share/sddm/…`, `/etc/sddm.conf.d/` | thème de connexion (avec `--with-sddm` uniquement) |

Les chemins `/home/<utilisateur>` des configs KDE sont adaptés à ton compte au
moment de l'installation, sans modifier les fichiers du dépôt.

## À faire à la main

- Raccourci global pour le lanceur et règle de flou KWin : voir [`configs/rofi/README.md`](configs/rofi/README.md).
- Se déconnecter / reconnecter pour que tout soit pris en compte.

## Dépannage

- **Le fond vidéo ne s'affiche pas** : vérifie que `plasma6-wallpapers-smart-video-wallpaper-reborn`
  est installé, puis choisis le plugin « Smart Video Wallpaper Reborn » dans
  Paramètres système → Fond d'écran. Si la lecture plante, le plugin documente un
  backend GStreamer alternatif.
- **Icônes manquantes dans le terminal** : le profil Konsole utilise
  « JetBrainsMono NFM » (paquet `ttf-jetbrains-mono-nerd`).
