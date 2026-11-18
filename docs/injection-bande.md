# Injection de la bande commune

L'en-tête et le pied de page du site de l'IFE forment la bande commune. Une page la reçoit deux fois. Au rendu, le format `ife-html` l'écrit dans la page, et cette version sert de repli. Au chargement, le script `/assets/ife-band.js`, servi par le site, la remplace par la version en ligne. Une modification de la bande atteint ainsi toutes les pages au chargement suivant, y compris celles qui ne sont plus rendues.

## Mécanisme

### Sources

La bande s'écrit à un seul endroit, dans l'extension :

- `_extensions/ife/html/header.html` et `html/footer.html` : le balisage de l'en-tête et du pied de page, partials Pandoc appelés par `template.html` ;
- `_extensions/ife/sass/` : les styles, dans `layout/_header.scss`, `layout/_footer.scss`, `components/_brand-button.scss`, `_social.scss` et `_skip-link.scss` ;
- `_extensions/ife/html/ife-band.js` : le script d'injection, sans le fragment ni le bouton du menu ;
- `_extensions/ife/html/nav-toggle.js` : le bouton du menu mobile, partial de `template.html`, sans signe dollar puisque Pandoc le lit comme un modèle ;
- `_extensions/ife/assets/img/` : les images de la bande ;
- `_extensions/ife/assets/.htaccess` : la règle de cache sous Apache.

### Fichiers communs

`scripts/build-assets.sh` construit deux fichiers à partir des sources, dans `_extensions/ife/assets/` :

- `ife-band.js`, le script d'injection, qui porte le fragment HTML de l'en-tête et du pied de page, avec l'habillage IFE par défaut, et le bouton du menu de `nav-toggle.js` ;
- `ife-band.css`, compilé à partir de `sass/band.scss`, qui habille la bande dans une page qui n'est pas rendue avec `quarto-ife`.

Les deux fichiers sont commités. `scripts/build-assets.sh --check` échoue s'ils ne correspondent plus aux sources.

### Mise en ligne

Les fichiers communs voyagent avec l'extension. Au rendu d'`ife_webhome`, son post-render `scripts/assets.R` copie `_extensions/ofceweb/ife/assets/` dans `_site/assets/`. Le site les sert alors sous `https://ife.eco/assets/`, et la recette sous `https://ife.staging.datachamp.fr/assets/`. Une modification de la bande se met donc en ligne par une version publiée de `quarto-ife`, suivie d'un déploiement d'`ife_webhome`.

Le navigateur revalide les fichiers communs à chaque page : `Cache-Control: no-cache` vient du `.htaccess` sous Apache, et de la location `/assets/` de `site/nginx.conf` du dépôt `clients/ofce/staging` sur la recette. Tant qu'un fichier n'a pas changé, le serveur répond 304, sans le renvoyer.

### Dans la page

Une page rendue avec `ife-html` charge `/assets/ife-band.css` et `/assets/ife-band.js` par un petit script en ligne de `<head>`. Quarto rend relatives les adresses écrites dans les attributs des balises : une page de `webhome`, servie sous `/ofce/`, chercherait alors les fichiers sous `/ofce/assets/`. Le script en ligne garde l'adresse absolue.

Au chargement, `ife-band.js` remplace `header.ife-header` et `footer.ife-footer`. Une page IFE|OFCE ou IFE|CEPII garde son logo : le script le lit dans la classe `ife-brand--ofce` ou `ife-brand--cepii` de `<body>`. Le bouton du menu mobile est branché par délégation sur `document`, et fonctionne donc sur la bande injectée. Le même code, `nav-toggle.js`, est écrit dans la page au rendu et porté par `ife-band.js`. Chaque branchement retire le précédent, et `ife-band.js` branche le sien après le chargement de la page : le comportement du menu suit donc lui aussi la dernière version publiée, et la page garde celui de son rendu si `ife-band.js` ne répond pas.

Une page figée, qui n'est plus rendue, reçoit l'accroche une seule fois, par `scripts/poser-accroche.R <dossier>` : la feuille et le script avant `</head>`, `<div data-ife-band="header"></div>` après `<body>` et `<div data-ife-band="footer"></div>` avant `</body>`. Un second passage ne change rien. La pose sur les pages publiées et le masquage de leur ancien en-tête se font à la bascule (#4124).

### Repli

Si `ife-band.js` ne répond pas, la page garde la bande écrite au rendu, sans espace vide. Le navigateur note seulement le 404 du fichier dans sa console. Sans JavaScript, la page affiche aussi la bande écrite au rendu, que lisent les robots d'indexation.

En local, avec `quarto preview`, `/assets/` n'existe pas : l'auteur voit la bande écrite au rendu par la version installée de `quarto-ife`, qui est celle des visiteurs dès qu'elle est publiée et déployée.

### Images

Les images de la bande sont servies sous `/assets/img/`. Les adresses `/www/…` restent servies par `ife_webhome`, pour qu'aucune page déjà publiée ne perde ses images.

Le thème compilé dans les pages garde `/www/` pour les deux logos en masque des boutons IFE|OFCE et IFE|CEPII : Quarto fait échouer le rendu quand une image appelée par la feuille de style manque dans le projet, et `ife_webhome` n'a ces images que dans `www/`. La variable Sass `$ife-img-path` vaut `/www` pour le thème et `/assets/img` pour `ife-band.css`.

Les logos anthracite IFE|OFCE et IFE|CEPII sont tirés des logos noirs de `ife_webhome/assets/`, avec la couleur `#29242F`, comme celui de l'IFE.

## Modifier la bande

1. Modifier `html/header.html`, `html/footer.html` ou les styles de la bande.
2. Lancer `scripts/build-assets.sh` depuis la racine du dépôt.
3. Publier une version (README, « Publier une version »).
4. Déployer `ife_webhome`, qui met les nouveaux fichiers communs en ligne.

## Essais

Deux techniques ont été comparées sur une page de test d'`ife_webhome`, avec ses pages IFE|OFCE et IFE|CEPII et trois pages figées de `webhome`, du blog et du nowcast :

- le script, décrit plus haut ;
- l'inclusion par le serveur (SSI), `<!--#include virtual="/assets/…" -->`, avec `Options +Includes` et `AddOutputFilter INCLUDES .html` dans un `.htaccess` sous Apache, et `ssi on` sous nginx.

Les essais du 2026-11-13 se sont faits en local, dans Chrome :

- **nginx** : la recette reproduite, avec le vhost d'`ansible-config` (`sub_filter` du widget de commentaires, `Accept-Encoding ""`), un conteneur `racine` à `/` et un conteneur `ofce` à `/ofce/`, chacun en `nginx:1.30-alpine` avec `site/nginx.conf` ;
- **Apache** : `httpd:2.4`, avec `.htaccess` permis et un cache par défaut de 15 minutes, comme l'en-tête que sert aujourd'hui `ife.eco`.

| Critère | Script, nginx | Script, Apache | SSI, nginx | SSI, Apache |
|---|---|---|---|---|
| Bande remplacée, pages IFE, IFE\|OFCE, IFE\|CEPII | oui | oui | oui | oui |
| Page servie sous `/ofce/` sur la recette | oui | sans objet | non : `/assets/` est dans un autre conteneur | sans objet |
| Pages figées avec l'accroche | oui, trois sur trois | oui, trois sur trois | non essayé | non essayé |
| Libellé modifié sur le serveur, visible sans nouveau rendu | oui | oui | non essayé | non essayé |
| 304 au second chargement | oui pour le script et la feuille | oui | non essayé | non essayé |
| Fichier commun absent | bande du rendu | bande du rendu | page sans bande | `[an error occurred while processing this directive]` affiché |
| JavaScript désactivé | bande du rendu | bande du rendu | sans objet : le serveur insère la bande | sans objet |
| À maintenir | une location nginx, un `.htaccess` | un `.htaccess` | `ssi on` et l'inclusion entre conteneurs | `Options +Includes` et le filtre `INCLUDES` |

Le premier essai servait le fragment dans un fichier `ife-band.html`, lu par le script. Sur la recette, le `sub_filter` du widget traite toute réponse `text/html` et retire son `ETag` et son `Last-Modified` : le fragment était renvoyé en entier à chaque page, sans 304. Le fragment est donc passé dans `ife-band.js`, que le filtre ne touche pas.

La bande injectée a été comparée, en capture d'écran au pixel, à celle de `main` (`73d88c4`), en bureau et en mobile : elle est identique pour l'IFE. Pour IFE|OFCE et IFE|CEPII, le logo s'affiche, alors qu'il manquait sur `main`, faute de fichier.

Restent à refaire sur les vrais serveurs : sur la recette `ife.staging.datachamp.fr` après la fusion dans `staging`, et sur l'hébergement OVH Pro, d'abord dans un dossier de test, puis sur `ife.eco` une fois le domaine rattaché (#4125).

## Décisions

- **2026-11-13** : la bande commune s'injecte par un script, servi sous `/assets/`. Il fonctionne de la même façon sous Apache et sous nginx, y compris pour les pages de `/ofce/` servies par un autre conteneur sur la recette, et il garde la bande écrite au rendu quand les fichiers communs manquent. Le SSI n'a pas de repli : sous Apache, il affiche un message d'erreur dans la page, et sous nginx il laisse la page sans bande. Décision de l'équipe Data Champ' (#4119).
- **2026-11-13** : le fragment HTML de la bande est dans `ife-band.js`, pas dans un fichier HTML à part, pour que le filtre du widget de la recette garde la revalidation (#4119).
