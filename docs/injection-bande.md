# Injection de la bande commune

L'en-tête et le pied de page du site de l'IFE forment la bande commune. Une page la reçoit deux fois. Au rendu, le format `ife-html` l'écrit dans la page, et cette version sert de repli. Au chargement, le script `/assets/ife-band.js`, servi par le site, la remplace par la version en ligne. Une modification de la bande atteint ainsi toutes les pages au chargement suivant, y compris celles qui ne sont plus rendues.

## Mécanisme

### Sources

La bande s'écrit à un seul endroit, dans l'extension :

- `_extensions/ife/html/header.html` et `html/footer.html` : le balisage de l'en-tête et du pied de page, partials Pandoc appelés par `template.html` ;
- `_extensions/ife/sass/` : les styles, dans `layout/_header.scss`, `layout/_footer.scss`, `components/_brand-button.scss`, `_social.scss` et `_skip-link.scss`, et les images de ces styles dans `_img-band.scss` ;
- `_extensions/ife/html/ife-band.js` : le script d'injection, sans le fragment ni le bouton du menu ;
- `_extensions/ife/html/nav-toggle.js` : le bouton du menu mobile, partial de `template.html`, sans signe dollar puisque Pandoc le lit comme un modèle ;
- `_extensions/ife/assets/img/` : les images de la bande, parmi toutes celles du format ;
- `_extensions/ife/assets/.htaccess` : la règle de cache sous Apache.

### Fichiers communs

`scripts/build-assets.sh` construit deux fichiers à partir des sources, dans `_extensions/ife/assets/` :

- `ife-band.js`, le script d'injection, qui porte le fragment HTML de l'en-tête et du pied de page, avec l'habillage IFE par défaut, et le bouton du menu de `nav-toggle.js` ;
- `ife-band.css`, compilé à partir de `sass/band.scss`, qui habille la bande dans une page qui n'est pas rendue avec `quarto-ife`.

Les deux fichiers sont commités. `scripts/build-assets.sh --check` échoue s'ils ne correspondent plus aux sources.

### Mise en ligne

Les fichiers communs voyagent avec l'extension. Au rendu d'`ife_webhome`, son post-render `scripts/assets.R` copie dans `_site/assets/` les fichiers de `_extensions/ofceweb/ife/assets/` et les seules images que `ife-band.js` et `ife-band.css` appellent sous `/assets/img/`. Le site les sert alors sous `https://ife.eco/assets/`. Une modification de la bande se met donc en ligne par une version publiée de `quarto-ife`, suivie d'un déploiement d'`ife_webhome`.

Le navigateur revalide les fichiers communs à chaque page : `Cache-Control: no-cache` vient du `.htaccess`. Tant qu'un fichier n'a pas changé, le serveur répond 304, sans le renvoyer.

### Dans la page

Une page rendue avec `ife-html` charge `/assets/ife-band.css` et `/assets/ife-band.js` par un petit script en ligne de `<head>`. Quarto rend relatives les adresses écrites dans les attributs des balises : une page de `webhome`, servie sous `/ofce/`, chercherait alors les fichiers sous `/ofce/assets/`. Le script en ligne garde l'adresse absolue.

Au chargement, `ife-band.js` remplace `header.ife-header` et `footer.ife-footer`. Une page IFE|OFCE ou IFE|CEPII garde son logo : le script le lit dans la classe `ife-brand--ofce` ou `ife-brand--cepii` de `<body>`. Le bouton du menu mobile est branché par délégation sur `document`, et fonctionne donc sur la bande injectée. Le même code, `nav-toggle.js`, est écrit dans la page au rendu et porté par `ife-band.js`. Chaque branchement retire le précédent, et `ife-band.js` branche le sien après le chargement de la page : le comportement du menu suit donc lui aussi la dernière version publiée, et la page garde celui de son rendu si `ife-band.js` ne répond pas.

Une page figée, qui n'est plus rendue, reçoit l'accroche une seule fois, par `scripts/poser-accroche.R <dossier>` : la feuille et le script avant `</head>`, `<div data-ife-band="header"></div>` après `<body>` et `<div data-ife-band="footer"></div>` avant `</body>`. Un second passage ne change rien.

### Repli

Si `ife-band.js` ne répond pas, la page garde la bande écrite au rendu, sans espace vide. Le navigateur note seulement le 404 du fichier dans sa console. Sans JavaScript, la page affiche aussi la bande écrite au rendu, que lisent les robots d'indexation.

En local, avec `quarto preview`, `/assets/` n'existe pas : l'auteur voit la bande écrite au rendu par la version installée de `quarto-ife`, qui est celle des visiteurs dès qu'elle est publiée et déployée.

### Images

La bande appelle ses images par deux chemins, selon la version qui s'affiche :

| Version de la bande | Chemin des images | Fichiers servis |
|---|---|---|
| Écrite au rendu dans la page | `site_libs/quarto-contrib/ife-img/`, relatif à la page | Copiés par Quarto dans le site rendu (README, « Images du format ») |
| Injectée par `ife-band.js`, ou habillée par `ife-band.css` | `/assets/img/` | Copiés par `scripts/assets.R` d'`ife_webhome`, servis par ife.eco seul |

`scripts/build-assets.sh` construit le fragment de `ife-band.js` avec `ife-img` à `/assets/img`, et `ife-band.css` avec `$ife-img-path` à `/assets/img`. Une page ouverte ailleurs qu'ife.eco garde la bande écrite au rendu, dont les images ne dépendent d'aucun site.

Une image du format n'existe qu'à un seul endroit, l'extension : `www/` d'`ife_webhome` ne garde que les images de contenu, et `/assets/img/` les images de la bande. Les anciennes adresses `ife.eco/www/<image>` des images du format ne sont plus servies, sans redirection, faute d'appel extérieur connu.

Les logos anthracite IFE|OFCE et IFE|CEPII sont tirés des logos noirs de `ife_webhome/assets/`, avec la couleur `#29242F`, comme celui de l'IFE.

## Modifier la bande

1. Modifier `html/header.html`, `html/footer.html` ou les styles de la bande.
2. Lancer `scripts/build-assets.sh` depuis la racine du dépôt.
3. Publier une version (README, « Publier une version »).
4. Déployer `ife_webhome`, qui met les nouveaux fichiers communs en ligne.

## Décisions

- **2026-11-26** : les images de la bande écrite au rendu sont livrées par l'extension, dans `site_libs/quarto-contrib/ife-img/`, comme toutes les images du format, pour qu'une page affiche ses images hors d'ife.eco et qu'un dépôt fonctionne sans `www/`. La bande injectée garde `/assets/img/`, puisqu'elle n'est servie que par ife.eco (#4118).
