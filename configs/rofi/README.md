# rofi-outer-wilds — Onduloscope

Lanceur d'applications Rofi (mode script Python) inspiré d'Outer Wilds.

## Installation (Arch / KDE Plasma 6)

Le plus simple : lancer `./install.sh` à la racine du dépôt. Il installe les
dépendances et copie ce dossier dans `~/.config/rofi/`.

À la main :

```bash
sudo pacman -S rofi ttf-jetbrains-mono-nerd python
mkdir -p ~/.config/rofi && cp -r configs/rofi/* ~/.config/rofi/
chmod +x ~/.config/rofi/run.sh ~/.config/rofi/launcher.py
```

Rofi ≥ 2.0 est nécessaire : le support Wayland (ex-`rofi-wayland`) est intégré
au paquet `rofi` officiel.

## Test immédiat

```bash
~/.config/rofi/run.sh
```

## Raccourci global KDE Plasma 6

Paramètres système → Raccourcis → Ajouter une commande…
- Commande : `~/.config/rofi/run.sh` (chemin complet : `/home/VOTRE_NOM/.config/rofi/run.sh`)
- Assignez par ex. `Meta+Espace`.

## Flou d'arrière-plan (KWin)

Paramètres système → Gestion des fenêtres → Règles de fenêtre → Ajouter :
- Correspondance : classe de fenêtre `rofi` (correspondance partielle)
- Propriété « Flou d'arrière-plan » → Forcer → Oui

Le fond est à 85 % d'opacité (`config.rasi`), le flou apparaît derrière.
Si la fenêtre n'est pas centrée ou n'a pas la bonne taille, ajoutez aussi
des règles « Position » / « Taille » sur la même classe.

## Favoris

`favoris.txt` : un identifiant `.desktop` (ou nom d'exécutable) par ligne.
`Alt+F` ajoute/retire le module sélectionné.

`state.json` et `stats.json` (état de l'interface, historique des 50 derniers
lancements) sont créés automatiquement à l'usage et ne sont pas versionnés.

## Limites connues de Rofi

- L'effet machine à écrire n'est pas réalisable : Rofi n'affiche que le
  texte final à chaque appel du script (un curseur `█` est ajouté à la place).
- Haut/Bas et Gauche/Droite sont gérés par le script pour que la télémétrie
  suive la sélection. Conséquence : les touches Gauche/Droite ne déplacent
  plus le curseur dans le champ de saisie (utilisez Ctrl+B / Ctrl+F),
  et `Ctrl+P/N` restent la navigation native.
- Avec un filtre saisi, les flèches Haut/Bas parcourent la liste complète de
  la fréquence, pas seulement les résultats filtrés.
- Le comportement exact des widgets (prompt/message déplacés dans le layout)
  dépend de la version de rofi : ce thème n'a pas pu être testé sous
  Rofi ici, seul le backend Python a été vérifié.
