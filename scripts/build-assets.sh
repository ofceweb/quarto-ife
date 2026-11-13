#!/usr/bin/env bash
# Construit les fichiers communs de la bande, servis par le site sous /assets/,
# à partir des sources de l'extension (docs/injection-bande.md) :
#   - _extensions/ife/assets/ife-band.js, à partir de html/ife-band.js, où il
#     place le fragment tiré de html/header.html et html/footer.html, avec
#     l'habillage IFE par défaut ;
#   - _extensions/ife/assets/ife-band.css, à partir de sass/band.scss.
# img/ et .htaccess sont des sources, écrites à la main.
#
# Usage, depuis la racine du dépôt :
#   scripts/build-assets.sh          écrit les deux fichiers ;
#   scripts/build-assets.sh --check  échoue s'ils ne correspondent pas aux sources.
set -euo pipefail

ext=_extensions/ife
out=$ext/assets
check=false
case "${1:-}" in
  "") ;;
  --check) check=true ;;
  *) echo "Usage: scripts/build-assets.sh [--check]" >&2; exit 2 ;;
esac

if [ ! -f "$ext/html/header.html" ]; then
  echo "À lancer depuis la racine du dépôt quarto-ife." >&2
  exit 2
fi

# Le sass livré avec Quarto, pour compiler comme le rendu des pages.
quarto_bin=$(quarto --paths | head -n 1 | tr -d '\r')
sass=$(find "$quarto_bin" -path '*dart-sass*' \( -name 'sass' -o -name 'sass.bat' \) -type f 2>/dev/null | head -n 1)
if [ -z "$sass" ]; then
  echo "sass introuvable sous $quarto_bin" >&2
  exit 1
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# Fragment : un modèle minimal qui appelle les deux partials. Pandoc les
# cherche dans le dossier du modèle.
cp "$ext/html/header.html" "$ext/html/footer.html" "$tmp/"
printf '%s\n' '$header.html()$' '$footer.html()$' > "$tmp/band.html"
echo "" | quarto pandoc -f markdown -t html --eol=lf --template "$tmp/band.html" -o "$tmp/fragment.html"
tr -d '\r' < "$tmp/fragment.html" > "$tmp/fragment.lf"

# Le fragment entre dans une chaîne String.raw`…` du script : il ne doit
# contenir ni accent grave, ni ${, ni barre oblique inverse.
if grep -qE '`|\$\{|\\' "$tmp/fragment.lf"; then
  echo "L'en-tête ou le pied contient \`, \${ ou \\, que le script ne peut pas porter." >&2
  exit 1
fi
tr -d '\r' < "$ext/html/ife-band.js" \
  | sed -e "/^__IFE_BAND_FRAGMENT__\$/{r $tmp/fragment.lf" -e 'd' -e '}' > "$tmp/ife-band.js"

"$sass" --silence-deprecation=import --no-source-map --style=expanded "$ext/sass/band.scss" "$tmp/ife-band.css"

if $check; then
  status=0
  for f in ife-band.js ife-band.css; do
    if ! diff -q --strip-trailing-cr "$tmp/$f" "$out/$f" > /dev/null 2>&1; then
      echo "$out/$f ne correspond pas aux sources : lancer scripts/build-assets.sh" >&2
      status=1
    fi
  done
  [ $status -eq 0 ] && echo "Fichiers communs à jour."
  exit $status
fi

mkdir -p "$out"
cp "$tmp/ife-band.js" "$tmp/ife-band.css" "$out/"
echo "Écrits : $out/ife-band.js, $out/ife-band.css"
