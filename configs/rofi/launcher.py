#!/usr/bin/env python3
"""
Onduloscope — lanceur d'applications Rofi (mode script) thème Outer Wilds.

Rofi appelle ce script :
  * sans argument au démarrage            (ROFI_RETV=0)
  * avec la ligne choisie sur Entrée      (ROFI_RETV=1, ROFI_INFO=<id .desktop>)
  * à chaque raccourci personnalisé       (ROFI_RETV=9+N, ROFI_INFO = ligne active)

Raccourcis personnalisés (définis dans config.rasi) :
  custom-1  Alt+F    RETV=10  basculer favori
  custom-2  Gauche   RETV=11  fréquence précédente
  custom-3  Droite   RETV=12  fréquence suivante
  custom-4  Haut     RETV=13  signal précédent
  custom-5  Bas      RETV=14  signal suivant

L'état (fréquence active, module sélectionné) est conservé dans state.json.
L'historique glissant des 50 derniers lancements est conservé dans stats.json
et alimente la jauge « INTENSITÉ DU SIGNAL » de la fiche de télémétrie.
"""

import html
import json
import os
import re
import shlex
import subprocess
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
FAV_FILE = BASE_DIR / "favoris.txt"
STATE_FILE = BASE_DIR / "state.json"
STATS_FILE = BASE_DIR / "stats.json"
HISTORY_SIZE = 50

# --- Palette -----------------------------------------------------------
CYAN = "#5ff5e8"
AMBER = "#e58f2a"
PALE = "#8be9fd"
GREY = "#a0a8b7"

DEFAULT_COMMENT = ("Signal stable détecté sur la fréquence locale. "
                   "Aucune donnée d'archive disponible.")

# --- Fréquences --------------------------------------------------------
FAVORITES = "★ FRÉQUENCES PRIORITAIRES"
GLOBAL = "SPECTRE GLOBAL"
FALLBACK = "FLUCTUATIONS QUANTIQUES"
FREQUENCIES = [
    FAVORITES,
    "BALISES EXTÉRIEURES",
    "OUTILS DE TRADUCTION",
    "PROGRAMME ODYSSÉE",
    "SIMULATEUR DE VOL",
    "ARCHIVES DU RÉSEAU LOCAL",
    "INTÉGRITÉ DE COQUE",
    "CARTOGRAPHIE STELLAIRE",
    "JOURNAL DE MISSION",
    FALLBACK,
    GLOBAL,
]

# Ordre = priorité (le plus spécifique d'abord, Utility en dernier).
CATEGORY_MAP = [
    ("Game", "SIMULATEUR DE VOL"),
    ("Development", "OUTILS DE TRADUCTION"),
    ("Network", "BALISES EXTÉRIEURES"),
    ("AudioVideo", "PROGRAMME ODYSSÉE"),
    ("Audio", "PROGRAMME ODYSSÉE"),
    ("Video", "PROGRAMME ODYSSÉE"),
    ("Graphics", "CARTOGRAPHIE STELLAIRE"),
    ("Office", "JOURNAL DE MISSION"),
    ("Settings", "INTÉGRITÉ DE COQUE"),
    ("System", "INTÉGRITÉ DE COQUE"),
    ("Utility", "ARCHIVES DU RÉSEAU LOCAL"),
]

FIELD_CODES = re.compile(r"%[a-zA-Z%]")


# --- Parsing .desktop --------------------------------------------------
def app_dirs():
    dirs = [Path.home() / ".local/share/applications"]
    for d in os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share").split(":"):
        if d:
            dirs.append(Path(d) / "applications")
    return dirs


def locale_keys():
    lang = os.environ.get("LC_MESSAGES") or os.environ.get("LANG") or "fr_FR.UTF-8"
    lang = lang.split(".")[0]
    keys = [lang]
    if "_" in lang:
        keys.append(lang.split("_")[0])
    return keys


def parse_desktop(path: Path, locales):
    data = {}
    in_entry = False
    try:
        with open(path, encoding="utf-8", errors="replace") as fh:
            for line in fh:
                line = line.strip()
                if line.startswith("["):
                    in_entry = line == "[Desktop Entry]"
                    continue
                if not in_entry or not line or line.startswith("#") or "=" not in line:
                    continue
                k, v = line.split("=", 1)
                data.setdefault(k.strip(), v.strip())
    except OSError:
        return None

    if data.get("Type", "Application") != "Application":
        return None
    if data.get("NoDisplay", "").lower() == "true" or data.get("Hidden", "").lower() == "true":
        return None
    if "Exec" not in data:
        return None

    name = data.get("Name")
    comment = data.get("Comment", "")
    for loc in locales:
        name = data.get(f"Name[{loc}]", name)
        comment = data.get(f"Comment[{loc}]", comment)
    if not name:
        return None

    exec_clean = FIELD_CODES.sub("", data["Exec"]).strip()
    cats = [c for c in data.get("Categories", "").split(";") if c]
    return {
        "id": path.name,
        "name": name,
        "comment": comment.strip(),
        "exec": exec_clean,
        "terminal": data.get("Terminal", "").lower() == "true",
        "categories": cats,
    }


def frequency_of(app):
    for cat, freq in CATEGORY_MAP:
        if cat in app["categories"]:
            return freq
    return FALLBACK


def load_apps():
    locales = locale_keys()
    apps = {}
    for d in app_dirs():  # le premier trouvé (utilisateur) l'emporte
        if not d.is_dir():
            continue
        for p in sorted(d.rglob("*.desktop")):
            app_id = p.name
            if app_id in apps:
                continue
            app = parse_desktop(p, locales)
            if app:
                app["freq"] = frequency_of(app)
                apps[app_id] = app
    return sorted(apps.values(), key=lambda a: a["name"].casefold())


# --- Favoris -----------------------------------------------------------
def read_favs():
    try:
        return [l.strip() for l in FAV_FILE.read_text(encoding="utf-8").splitlines()
                if l.strip() and not l.startswith("#")]
    except OSError:
        return []


def exec_basename(app):
    try:
        return os.path.basename(shlex.split(app["exec"])[0])
    except (ValueError, IndexError):
        return ""


def fav_matches(app, entry):
    return entry in (app["id"], app["id"].removesuffix(".desktop"), exec_basename(app))


def is_fav(app, favs):
    return any(fav_matches(app, f) for f in favs)


def toggle_fav(app):
    favs = read_favs()
    if is_fav(app, favs):
        favs = [f for f in favs if not fav_matches(app, f)]
    else:
        favs.append(app["id"])
    FAV_FILE.write_text("\n".join(favs) + ("\n" if favs else ""), encoding="utf-8")


# --- État --------------------------------------------------------------
def load_state():
    try:
        return json.loads(STATE_FILE.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return {"freq": 0, "sel": None}


def save_state(state):
    try:
        STATE_FILE.write_text(json.dumps(state), encoding="utf-8")
    except OSError:
        pass


# --- Historique glissant des lancements --------------------------------
def load_history():
    try:
        hist = json.loads(STATS_FILE.read_text(encoding="utf-8")).get("history", [])
        return [h for h in hist if isinstance(h, str)][-HISTORY_SIZE:]
    except (OSError, ValueError, AttributeError):
        return []


def record_launch(app_id):
    history = load_history()
    history = history[-(HISTORY_SIZE - 1):] + [app_id]      # fenêtre glissante
    try:
        STATS_FILE.write_text(json.dumps({"history": history}), encoding="utf-8")
    except OSError:
        pass


def signal_level(app_id, history):
    """Retourne (occurrences, barres 0..5, pourcentage, libellé).

    Intensité relative : occurrences de l'application rapportées à celle de
    l'application la plus lancée dans la fenêtre glissante.
      0 occurrence     -> 0 barre   (  0 %)  AUCUN SIGNAL
      1 barre          ->            20 %    RÉSIDUEL
      2-3 barres       ->        40-60 %     STABLE
      4-5 barres       ->       80-100 %     OPTIMAL
    """
    counts = {}
    for h in history:
        counts[h] = counts.get(h, 0) + 1
    n = counts.get(app_id, 0)
    if n == 0:
        return 0, 0, 0, "AUCUN SIGNAL"
    bars = -(-5 * n // max(counts.values()))                 # ceil(5 * n / max) : 1..5
    label = "RÉSIDUEL" if bars == 1 else "STABLE" if bars <= 3 else "OPTIMAL"
    return n, bars, bars * 20, label


# --- Statut pgrep ------------------------------------------------------
def is_running(app):
    base = exec_basename(app)
    if not base:
        return False
    # pgrep -x compare avec le nom de processus (tronqué à 15 caractères)
    r = subprocess.run(["pgrep", "-x", base[:15]], capture_output=True)
    return r.returncode == 0


# --- Lancement ---------------------------------------------------------
def launch(app):
    cmd = shlex.split(app["exec"])
    if app["terminal"]:
        cmd = ["konsole", "-e"] + cmd
    subprocess.Popen(cmd, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                     stderr=subprocess.DEVNULL, start_new_session=True,
                     close_fds=True)


# --- Rendu Rofi --------------------------------------------------------
def clean(s):
    """Retire tout caractère de contrôle qui casserait le protocole script de Rofi."""
    s = s.replace("\0", "").replace("\x1f", "")
    return " ".join(s.split())          # aplati \n, \r, \t et espaces multiples


def esc(s):
    return html.escape(clean(s), quote=False)


def option_value(markup):
    """Valeur d'une option `\\0clé\\x1fvaleur` : Rofi coupe l'entrée à chaque
    saut de ligne réel, donc on envoie les retours à la ligne sous forme de
    référence Pango `&#10;` (le message est rendu en markup)."""
    return markup.replace("\r", "").replace("\x1f", "").replace("\n", "&#10;")


def apps_in_frequency(apps, freq_idx):
    if freq_idx == 0:
        favs = read_favs()
        return [a for a in apps if is_fav(a, favs)]
    name = FREQUENCIES[freq_idx]
    if name == GLOBAL:                       # toutes les applications du système
        return list(apps)
    return [a for a in apps if a["freq"] == name]


def tuner_line(idx):
    n = len(FREQUENCIES)
    prev, cur, nxt = FREQUENCIES[(idx - 1) % n], FREQUENCIES[idx], FREQUENCIES[(idx + 1) % n]
    # Rendu Pango : voisines discrètes, fréquence active en grand, gras, ambre.
    return (f"<span size='small' foreground='{GREY}'>[ {esc(prev)} ]</span>"
            f"    <span size='large' weight='bold' foreground='{AMBER}'>◄  {esc(cur)}  ►</span>"
            f"    <span size='small' foreground='{GREY}'>[ {esc(nxt)} ]</span>")


def telemetry(app, freq_name, history, favs):
    lines = [f"<span foreground='{GREY}'>FRÉQUENCE : </span>"
             f"<span foreground='{CYAN}'>{esc(freq_name)}</span>"]
    if app is not None and freq_name == GLOBAL:
        lines.append(f"<span foreground='{GREY}'>FRÉQUENCE D'ORIGINE : </span>"
                     f"<span foreground='{CYAN}'>{esc(app['freq'])}</span>")
    if app is None:
        lines.append(f"\n<span foreground='{GREY}'>AUCUN SIGNAL SUR CETTE FRÉQUENCE.</span>")
        if freq_name == FAVORITES:
            lines.append(f"<span foreground='{PALE}'>Sélectionnez un module "
                         f"puis Alt+F pour l'ajouter ici.</span>")
        return "\n".join(lines)

    running = is_running(app)
    status = (f"<span foreground='{AMBER}'>MODULE ACTIF // EN COURS D'EXÉCUTION</span>" if running
              else f"<span foreground='{CYAN}'>EN VEILLE // DISPONIBLE</span>")
    comment = app["comment"] or DEFAULT_COMMENT
    n, bars, pct, label = signal_level(app["id"], history)
    fav_line = (f"<span foreground='{GREY}'>FAVORI : </span>"
                f"<span foreground='{AMBER}'>OUI [★ VERROUILLÉ]</span>" if is_fav(app, favs)
                else f"<span foreground='{GREY}'>FAVORI : NON [☆ DISPONIBLE]</span>")
    lines += [
        f"<span foreground='{GREY}'>MODULE    : </span><span foreground='{PALE}'>{esc(app['name'])}</span>",
        f"<span foreground='{GREY}'>STATUT    : </span>{status}",
        f"<span foreground='{GREY}'>INTENSITÉ DU SIGNAL : </span>"
        f"<span foreground='{CYAN}'>{'▰' * bars}{'▱' * (5 - bars)} {pct}%</span>"
        f"<span foreground='{GREY}'> // </span><span foreground='{AMBER}'>{label}</span>"
        f"<span foreground='{GREY}'> ({n}/{HISTORY_SIZE} TRANSMISSIONS RÉCENTES)</span>",
        fav_line,
        "",
        f"<span foreground='{GREY}'>TRANSCRIPTION DU SIGNAL :</span>",
        f"<span foreground='{PALE}'>\"{esc(comment)}\"</span> <span foreground='{AMBER}'>█</span>",
        "",
        f"<span foreground='{GREY}'>VECTEUR D'ACCÈS :</span>",
        f"<span foreground='{PALE}'>{esc(app['exec'])}</span>",
    ]
    return "\n".join(lines)


def render(apps, state):
    idx = state["freq"] % len(FREQUENCIES)
    items = apps_in_frequency(apps, idx)
    ids = [a["id"] for a in items]
    if state.get("sel") not in ids:
        state["sel"] = ids[0] if ids else None
    save_state(state)

    out = [
        f"\0prompt\x1f{tuner_line(idx)}",
        "\0no-custom\x1ftrue",
        "\0use-hot-keys\x1ftrue",        # sans ça, kb-custom-* est ignoré en mode script
        "\0keep-selection\x1ftrue",      # laisse new-selection s'appliquer au rechargement
        "\0keep-filter\x1ftrue",
        "\0markup-rows\x1ffalse",
    ]
    sel_app = next((a for a in items if a["id"] == state["sel"]), None)
    history, favs = load_history(), read_favs()
    out.append("\0message\x1f" + option_value(
        telemetry(sel_app, FREQUENCIES[idx], history, favs)))
    if state["sel"] in ids:
        out.append(f"\0new-selection\x1f{ids.index(state['sel'])}")

    if not items:
        out.append("— aucun signal détecté —\0nonselectable\x1ftrue")
    for a in items:
        prefix = "◈ " if a["id"] == state["sel"] else "◇ "
        star = "★ " if is_fav(a, favs) else ""
        out.append(f"{prefix}{star}{clean(a['name'])}\0info\x1f{a['id']}")
    sys.stdout.write("\n".join(out) + "\n")


def main():
    retv = int(os.environ.get("ROFI_RETV", "0"))
    info = os.environ.get("ROFI_INFO", "")
    apps = load_apps()
    by_id = {a["id"]: a for a in apps}

    if retv == 0 and len(sys.argv) == 1:      # ouverture : on repart de zéro
        state = {"freq": 0, "sel": None}
        render(apps, state)
        return

    state = load_state()

    if retv == 1:                              # Entrée
        app = by_id.get(info)
        if app:
            record_launch(app["id"])
            launch(app)
        return                                 # aucune sortie => Rofi se ferme

    n = len(FREQUENCIES)
    # kb-custom-N => ROFI_RETV = 9 + N
    if retv == 10:                             # custom-1 : Alt+F
        target_id = info if (info and info in by_id) else state.get("sel")
        if target_id in by_id:
            toggle_fav(by_id[target_id])
            state["sel"] = target_id
    elif retv == 11:                           # custom-2 : Gauche
        state["freq"] = (state["freq"] - 1) % n
        state["sel"] = None
    elif retv == 12:                           # custom-3 : Droite
        state["freq"] = (state["freq"] + 1) % n
        state["sel"] = None
    elif retv in (13, 14):                     # custom-4 : Haut / custom-5 : Bas
        ids = [a["id"] for a in apps_in_frequency(apps, state["freq"])]
        if ids:
            step = -1 if retv == 13 else 1
            # ligne active selon Rofi, sinon dernier module mémorisé dans l'état
            cur_id = info if (info and info in ids) else state.get("sel")
            if cur_id in ids:
                state["sel"] = ids[(ids.index(cur_id) + step) % len(ids)]
            else:                              # rien de mémorisé : première / dernière
                state["sel"] = ids[0] if step == 1 else ids[-1]
    render(apps, state)


if __name__ == "__main__":
    main()
