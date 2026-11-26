# quarto-ife

L'extension Quarto `quarto-ife` porte la charte du site de l'IFE : le format `ife-html`, qui dessine l'en-tête, le pied de page et le style des pages, et le type de projet `ife-website`, qui déclare les shortcodes des blocs de la page d'accueil. C'est la seule source de cette extension, et chaque dépôt du site en installe une version publiée.

## Contenu

- `_extensions/ife/` fournit le format `ife-html`. `template.html` dessine la page, avec l'en-tête et le pied de page de `html/header.html` et `html/footer.html`. `sass/` porte la charte et le rendu visuel, et `brand.lua` choisit l'habillage selon la marque du dépôt et livre les images du format. `assets/img/` contient toutes les images du format, et `assets/` les fichiers communs de la bande, que le site sert sous `/assets/`.
- `scripts/` contient `build-assets.sh`, qui construit les fichiers communs de la bande et la feuille des images, `test-site.sh`, qui rend le site de test et vérifie ses images, et `poser-accroche.R`, qui prépare une page figée à recevoir la bande.
- `tests/site-sans-www/` est un site de test sans dossier `www/`, qui appelle l'en-tête, le pied de page et les blocs de l'accueil.
- `docs/injection-bande.md` décrit l'injection de la bande commune dans toutes les pages du site.
- `_extensions/ife-website/` définit le type de projet `ife-website`. Il pose le favicon et le bandeau cookies, et déclare les shortcodes des blocs, un fichier par bloc dans `home/`.

## Installer l'extension

Une version publiée est une étiquette `vX.Y.Z` du dépôt. Dans un projet Quarto, la fonction `update_quarto_ife()` du package [`ofceweb`](https://github.com/ofceweb/ofceweb) installe la dernière version publiée.

``` r
ofceweb::update_quarto_ife()
```

Sans `ofceweb`, l'extension s'installe à la racine du projet avec la version voulue.

``` bash
quarto add ofceweb/quarto-ife@v0.2.0 --no-prompt
```

Quarto nomme le dossier d'installation d'après le propriétaire du dépôt GitHub : l'extension arrive dans `_extensions/ofceweb/`, qui se commite avec le projet. Dans un projet de type `ife-website` dont l'extension manque, `quarto add` s'arrête sur ce type inconnu, alors que `update_quarto_ife()` l'installe sans difficulté.

## Déclarer la marque

Le champ `institution` de `_quarto.yml` déclare la marque du dépôt, et le format `ife-html` en tire l'habillage des pages.

``` yaml
institution: ofce
```

| `institution` | Habillage | Logo, dans `_extensions/ife/assets/img/` | Couleur d'accent |
|---|---|---|---|
| `ife`, ou champ absent | IFE | `IFE_Institut_logo_anthrancite.svg` | anthracite `#29242F` |
| `ofce` | IFE\|OFCE | `IFE-OFCE_logo_anthracite.svg` | bordeaux `#7D0000` |
| `cepii` | IFE\|CEPII | `IFE-CEPII_logo_anthracite.svg` | turquoise `#21606E` |

Une autre valeur produit un avertissement au rendu et l'habillage de l'IFE. Pour IFE|OFCE et IFE|CEPII, `<body>` porte la classe `ife-brand--ofce` ou `ife-brand--cepii`. La couleur d'accent est la variable CSS `--ife-accent`, que les styles des pages emploient à mesure que les maquettes en fixent l'usage.

## Images du format

Toutes les images que le format appelle sont dans `_extensions/ife/assets/img/` : logos, icônes de l'en-tête et du pied de page, masques, pictos des blocs et drapeaux. Au rendu, `brand.lua` les déclare à Quarto comme fichiers de la dépendance `ife-img`, avec la feuille `ife-images.css` qui porte les images des styles. Quarto les copie dans `_site/site_libs/quarto-contrib/ife-img/`, sans rien écrire dans le projet, et rend leur adresse relative à chaque page. Un projet n'a donc besoin d'aucun dossier `www/` : ses pages affichent leurs images en local, depuis le disque, et sur tout hébergement, y compris dans un sous-dossier.

Le thème n'appelle aucune image : Quarto cherche une image appelée par le thème dans le projet rendu, et le rendu échoue si elle manque. Une nouvelle image de style va dans `sass/_img-pages.scss`, ou dans `sass/_img-band.scss` si la bande l'emploie.

Le format suppose un site Quarto : une page rendue seule, hors d'un projet, range ses dépendances ailleurs que dans `site_libs/`, et ses images n'y sont pas.

Les images de contenu des pages, comme les illustrations des blocs, restent dans le projet qui les emploie.

## Mettre à jour l'extension

Un dépôt de site appelle `update_quarto_ife()` en `pre-render` de son `_quarto.yml`, si bien qu'il récupère la dernière version publiée à chaque rendu, sur le poste comme dans son workflow GitHub. Si GitHub ne répond pas, le rendu garde la version présente et affiche un avertissement.

``` yaml
project:
  pre-render: Rscript -e "ofceweb::update_quarto_ife()"
```

Un dépôt de document (working paper, policy brief, prévision) garde la version installée à sa création, pour qu'un document publié garde sa présentation. Un appel à `ofceweb::update_quarto_ife()` le fait passer à la dernière version.

## Publier une version

Une modification de l'extension n'atteint aucun dépôt tant qu'elle n'est pas publiée. Pour publier une version :

1. Passer `version` au nouveau numéro dans `_extensions/ife/_extension.yml` et `_extensions/ife-website/_extension.yml`, qui gardent toujours le même.
2. Lancer `scripts/build-assets.sh`, qui reconstruit les fichiers communs de la bande à partir de l'en-tête, du pied de page et de leurs styles, ainsi que `ife-images.css`.
3. Lancer `scripts/test-site.sh`, qui rend le site de test sans `www/` et échoue si une image appelée par une page ou une feuille de style manque ou garde un chemin absolu.
4. Commiter, puis pousser `main`.
5. Vérifier avec `scripts/build-assets.sh --check` que les fichiers construits correspondent aux sources et qu'aucune image n'est appelée hors de `assets/img/`, puis créer sur GitHub l'étiquette `vX.Y.Z` et sa release.
6. Déployer `ife_webhome`, dont le rendu met en ligne les fichiers communs sous `/assets/` : une modification de la bande atteint alors toutes les pages, sans nouveau rendu des autres dépôts ([docs/injection-bande.md](docs/injection-bande.md)).

Les sites prennent la nouvelle version à leur rendu suivant.
