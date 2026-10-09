#!/usr/bin/env bash
# Si Rofi est déjà ouvert, fermer le processus (effet toggle sur Meta)
if pkill -x rofi; then
    exit 0
fi

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
touch "$DIR/favoris.txt"
exec rofi -show ow \
    -modi "ow:python3 $DIR/launcher.py" \
    -config "$DIR/config.rasi" \
    -no-fixed-num-lines