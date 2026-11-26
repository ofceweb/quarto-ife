#!/usr/bin/env bash
# Rend le site de test tests/site-sans-www/ avec l'extension du dépôt, puis
# vérifie que chaque image locale appelée par les pages rendues (src, srcset)
# et par leurs feuilles de style (url()) a un chemin relatif et existe dans
# _site/, à la racine comme dans le sous-dossier. Le site de test n'a pas de
# dossier www/ : une image appelée hors de l'extension y manque.
# Il vérifie aussi que l'accueil appelle les images attendues dont l'absence
# ne casserait aucun lien, comme un drapeau trouvé par son code de pays.
#
# Le rendu se fait dans un dossier temporaire, où l'extension est installée
# sous _extensions/ofceweb/, comme le fait quarto add : le dépôt reste propre.
#
# Usage, depuis la racine du dépôt :
#   scripts/test-site.sh          rend, vérifie, puis supprime le rendu ;
#   scripts/test-site.sh --keep   garde le rendu et affiche son chemin.
set -euo pipefail

keep=false
case "${1:-}" in
  "") ;;
  --keep) keep=true ;;
  *) echo "Usage: scripts/test-site.sh [--keep]" >&2; exit 2 ;;
esac

if [ ! -d tests/site-sans-www ] || [ ! -d _extensions/ife ]; then
  echo "À lancer depuis la racine du dépôt quarto-ife." >&2
  exit 2
fi

tmp=$(mktemp -d)
if $keep; then
  trap 'echo "Rendu gardé : $tmp/site"' EXIT
else
  trap 'rm -rf "$tmp"' EXIT
fi

cp -r tests/site-sans-www "$tmp/site"
mkdir -p "$tmp/site/_extensions/ofceweb"
cp -r _extensions/ife _extensions/ife-website "$tmp/site/_extensions/ofceweb/"

(cd "$tmp/site" && quarto render 2>&1 | tail -n 30; exit "${PIPESTATUS[0]}")

python3 - "$tmp/site/_site" <<'EOF'
import pathlib, re, sys
from urllib.parse import unquote, urlsplit

site = pathlib.Path(sys.argv[1])
pages = sorted(site.rglob("*.html"))
sheets = sorted(site.rglob("*.css"))
missing = []
checked = 0
# Images que la page doit appeler. Un drapeau introuvable est simplement omis
# par components.lua : sans cette liste, sa disparition passerait inaperçue.
expected = {
    "index.html": ["site_libs/quarto-contrib/ife-img/flags/it.svg"],
}
called = {}

def local(ref):
    ref = ref.strip().strip("'\"")
    if not ref or ref.startswith(("#", "data:", "mailto:", "javascript:")):
        return None
    parts = urlsplit(ref)
    if parts.scheme or parts.netloc:
        return None
    return unquote(parts.path) or None

def check(owner, ref):
    global checked
    path = local(ref)
    if path is None:
        return
    checked += 1
    called.setdefault(owner, set()).add(path)
    # Un chemin absolu casse les pages ouvertes depuis le disque ou servies
    # dans un sous-dossier : seul un chemin relatif à la page est admis.
    if path.startswith("/"):
        missing.append(f"{owner.relative_to(site)} : {ref} (chemin absolu)")
        return
    if not (owner.parent / path).resolve().is_file():
        missing.append(f"{owner.relative_to(site)} : {ref}")

for page in pages:
    # Une image dans un commentaire HTML n'est pas chargée.
    html = re.sub(r"<!--.*?-->", "", page.read_text(encoding="utf-8"), flags=re.S)
    for ref in re.findall(r'<img[^>]*?\ssrc="([^"]*)"', html):
        check(page, ref)
    for srcset in re.findall(r'\ssrcset="([^"]*)"', html):
        for item in srcset.split(","):
            check(page, item.split()[0] if item.split() else "")
    for style in re.findall(r'style="([^"]*)"', html):
        for ref in re.findall(r'url\(([^)]*)\)', style):
            check(page, ref)
for sheet in sheets:
    css = sheet.read_text(encoding="utf-8")
    for ref in re.findall(r'url\(([^)]*)\)', css):
        check(sheet, ref)

if not pages:
    sys.exit("Aucune page rendue.")
for name, images in expected.items():
    page = site / name
    refs = {(page.parent / ref).resolve() for ref in called.get(page, ())}
    for image in images:
        if (site / image).resolve() not in refs:
            missing.append(f"{name} : {image} (attendue, non appelée)")
if missing:
    print(f"{len(missing)} image(s) introuvable(s) dans _site/ :", file=sys.stderr)
    for line in missing:
        print("  " + line, file=sys.stderr)
    sys.exit(1)
print(f"{len(pages)} pages, {len(sheets)} feuilles de style : {checked} images locales, toutes présentes.")
EOF
