#!/usr/bin/env bash
# Construit les fichiers communs de la bande, servis par le site sous /assets/,
# à partir des sources de l'extension (docs/injection-bande.md) :
#   - _extensions/ife/assets/ife-band.js, à partir de html/ife-band.js, où il
#     place le fragment tiré de html/header.html et html/footer.html, avec
#     l'habillage IFE par défaut, et le bouton du menu de html/nav-toggle.js ;
#   - _extensions/ife/assets/ife-band.css, à partir de sass/band.scss.
# Il construit aussi la feuille des images des pages, livrée par la dépendance
# ife-img de brand.lua :
#   - _extensions/ife/ife-images.css, à partir de sass/ife-images.scss.
# img/ et .htaccess sont des sources, écrites à la main.
#
# Usage, depuis la racine du dépôt :
#   scripts/build-assets.sh          écrit les trois fichiers ;
#   scripts/build-assets.sh --check  échoue s'ils ne correspondent pas aux
#                                    sources, ou si une image appelée par
#                                    l'extension manque dans assets/img/.
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
# cherche dans le dossier du modèle. La bande injectée n'est servie que par
# ife.eco, qui publie les images sous /assets/img/.
cp "$ext/html/header.html" "$ext/html/footer.html" "$tmp/"
printf '%s\n' '$header.html()$' '$footer.html()$' > "$tmp/band.html"
echo "" | quarto pandoc -f markdown -t html --eol=lf -V ife-img=/assets/img --template "$tmp/band.html" -o "$tmp/fragment.html"
tr -d '\r' < "$tmp/fragment.html" > "$tmp/fragment.lf"

# Le fragment entre dans une chaîne String.raw`…` du script : il ne doit
# contenir ni accent grave, ni ${, ni barre oblique inverse.
if grep -qE '`|\$\{|\\' "$tmp/fragment.lf"; then
  echo "L'en-tête ou le pied contient \`, \${ ou \\, que le script ne peut pas porter." >&2
  exit 1
fi
# Le bouton du menu est aussi un partial de template.html : Pandoc y lirait un
# signe dollar comme une variable.
if grep -q '\$' "$ext/html/nav-toggle.js"; then
  echo "html/nav-toggle.js contient un signe dollar, que Pandoc interpréterait." >&2
  exit 1
fi
tr -d '\r' < "$ext/html/nav-toggle.js" > "$tmp/nav-toggle.lf"
tr -d '\r' < "$ext/html/ife-band.js" \
  | sed -e "/^__IFE_BAND_FRAGMENT__\$/{r $tmp/fragment.lf" -e 'd' -e '}' \
        -e "/^__IFE_NAV_TOGGLE__\$/{r $tmp/nav-toggle.lf" -e 'd' -e '}' > "$tmp/ife-band.js"

"$sass" --silence-deprecation=import --no-source-map --style=expanded "$ext/sass/band.scss" "$tmp/ife-band.css"
"$sass" --silence-deprecation=import --no-source-map --style=expanded "$ext/sass/ife-images.scss" "$tmp/ife-images.css"

# Contrôle des images (D16 de OP #4118) : toute image du format vit dans
# assets/img/. Échoue si un fichier de l'extension appelle /www/ hors d'une
# ligne de commentaire, ou si une image appelée par son chemin dans
# l'extension manque dans assets/img/.
check_images() {
  local status=0 ref
  local www
  www=$(grep -rnE '/www/' _extensions --include='*.lua' --include='*.scss' --include='*.html' --include='*.js' \
          | grep -vE '^[^:]+:[0-9]+:[[:space:]]*(--|//|/\*|\*)' || true)
  if [ -n "$www" ]; then
    echo "Image appelée en /www/, hors de l'extension :" >&2
    echo "$www" >&2
    status=1
  fi
  # Chemins écrits dans les partials ($ife-img$/…), en Lua (IMG .. "/…"),
  # dans le script de la bande (/assets/img/…) et dans ife-images.css (url(./…)).
  while IFS= read -r ref; do
    if [ ! -f "$ext/assets/img/$ref" ]; then
      echo "Image introuvable dans $ext/assets/img/ : $ref" >&2
      status=1
    fi
  done < <(
    {
      grep -rhoE '\$ife-img\$/[^"$]+' "$ext/html" | sed 's|^\$ife-img\$/||'
      grep -rhoE 'IMG \.\. "/[^"]+"' _extensions --include='*.lua' | sed -E 's|^IMG \.\. "/||; s|"$||'
      grep -rhoE '/assets/img/[^"]+' "$ext/html/ife-band.js" | sed 's|^/assets/img/||'
      grep -hoE 'url\("\./[^"]+"\)' "$tmp/ife-images.css" | sed -E 's|^url\("\./||; s|"\)$||'
    } | grep -v '/$' | sort -u
  )
  return $status
}

if $check; then
  status=0
  for f in "$out/ife-band.js" "$out/ife-band.css" "$ext/ife-images.css"; do
    if ! diff -q --strip-trailing-cr "$tmp/$(basename "$f")" "$f" > /dev/null 2>&1; then
      echo "$f ne correspond pas aux sources : lancer scripts/build-assets.sh" >&2
      status=1
    fi
  done
  check_images || status=1
  [ $status -eq 0 ] && echo "Fichiers communs à jour, images présentes."
  exit $status
fi

mkdir -p "$out"
cp "$tmp/ife-band.js" "$tmp/ife-band.css" "$out/"
cp "$tmp/ife-images.css" "$ext/"
echo "Écrits : $out/ife-band.js, $out/ife-band.css, $ext/ife-images.css"
