# quarto-ife

L'extension Quarto `quarto-ife` porte la charte du site de l'IFE : le format `ife-html`, qui dessine l'en-tête, le pied de page et le style des pages, et le type de projet `ife-website`, qui déclare les shortcodes des blocs de la page d'accueil. C'est la seule source de cette extension, et chaque dépôt du site en installe une version publiée.

## Contenu

- `_extensions/ife/` fournit le format `ife-html`. `template.html` dessine la page, avec l'en-tête et le pied de page de `html/header.html` et `html/footer.html`. `sass/` porte la charte et le rendu visuel, et `brand.lua` choisit l'habillage selon la marque du dépôt. `assets/` contient les fichiers communs de la bande et ses images, que le site sert sous `/assets/`.
- `scripts/` contient `build-assets.sh`, qui construit les fichiers communs de la bande, et `poser-accroche.R`, qui prépare une page figée à recevoir la bande.
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

| `institution` | Habillage | Logo | Couleur d'accent |
|---|---|---|---|
| `ife`, ou champ absent | IFE | `/assets/img/IFE_Institut_logo_anthrancite.svg` | anthracite `#29242F` |
| `ofce` | IFE\|OFCE | `/assets/img/IFE-OFCE_logo_anthracite.svg` | bordeaux `#7D0000` |
| `cepii` | IFE\|CEPII | `/assets/img/IFE-CEPII_logo_anthracite.svg` | turquoise `#21606E` |

Une autre valeur produit un avertissement au rendu et l'habillage de l'IFE. Pour IFE|OFCE et IFE|CEPII, `<body>` porte la classe `ife-brand--ofce` ou `ife-brand--cepii`. La couleur d'accent est la variable CSS `--ife-accent`, que les styles des pages emploient à mesure que les maquettes en fixent l'usage.

Les images de la bande (logos, icônes, masques) sont dans `_extensions/ife/assets/img/`. La page les appelle en `/assets/img/…`, et `ife_webhome` les publie sous `ife.eco` avec les autres fichiers communs. Le thème garde `/www/…` pour les deux logos en masque des boutons IFE|OFCE et IFE|CEPII, car Quarto exige qu'une image appelée par la feuille de style soit dans le projet rendu, et `www/` d'`ife_webhome` continue de les servir. Un dépôt rendu ailleurs, sans ces images, affiche ses pages sans logo ni icônes.

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
2. Lancer `scripts/build-assets.sh`, qui reconstruit les fichiers communs de la bande à partir de l'en-tête, du pied de page et de leurs styles.
3. Commiter, puis pousser `main`.
4. Vérifier avec `scripts/build-assets.sh --check` que les fichiers communs correspondent aux sources, puis créer sur GitHub l'étiquette `vX.Y.Z` et sa release.
5. Déployer `ife_webhome`, dont le rendu met en ligne les fichiers communs sous `/assets/` : une modification de la bande atteint alors toutes les pages, sans nouveau rendu des autres dépôts ([docs/injection-bande.md](docs/injection-bande.md)).

Les sites prennent la nouvelle version à leur rendu suivant.
