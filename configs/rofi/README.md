# rofi-outer-wilds — Onduloscope

Lanceur d'applications Rofi-Wayland (mode script Python) inspiré d'Outer Wilds.

## Installation (Arch / KDE Plasma 6)

```bash
sudo pacman -S rofi-wayland ttf-jetbrains-mono python
git clone <votre-repo> ~/.config/rofi-outer-wilds
chmod +x ~/.config/rofi-outer-wilds/run.sh ~/.config/rofi-outer-wilds/launcher.py
```

## Test immédiat

```bash
~/.config/rofi-outer-wilds/run.sh
```

## Raccourci global KDE Plasma 6

Paramètres système → Raccourcis → Ajouter une commande…
- Commande : `/home/VOTRE_NOM/.config/rofi-outer-wilds/run.sh`
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
  dépend de la version de rofi-wayland : ce thème n'a pas pu être testé sous
  Rofi ici, seul le backend Python a été vérifié.
