# quarto-ife

L'extension Quarto `quarto-ife` porte la charte du site de l'IFE : le format `ife-html`, qui dessine l'en-tête, le pied de page et le style des pages, et le type de projet `ife-website`, qui déclare les shortcodes des blocs de la page d'accueil. C'est la seule source de cette extension, et chaque dépôt du site en installe une version publiée.

## Contenu

- `_extensions/ife/` fournit le format `ife-html`. `template.html` dessine l'en-tête et le pied de page, `sass/` porte la charte et le rendu visuel, et `brand.lua` choisit l'habillage selon la marque du dépôt.
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
| `ife`, ou champ absent | IFE | `/www/IFE_Institut_logo_anthrancite.svg` | anthracite `#29242F` |
| `ofce` | IFE\|OFCE | `/www/IFE-OFCE_logo_anthracite.svg` | bordeaux `#7D0000` |
| `cepii` | IFE\|CEPII | `/www/IFE-CEPII_logo_anthracite.svg` | turquoise `#21606E` |

Une autre valeur produit un avertissement au rendu et l'habillage de l'IFE. Pour IFE|OFCE et IFE|CEPII, `<body>` porte la classe `ife-brand--ofce` ou `ife-brand--cepii`. La couleur d'accent est la variable CSS `--ife-accent`, que les styles des pages emploient à mesure que les maquettes en fixent l'usage.

Les images de l'extension (logos, icônes, masques) ne sont pas dans l'extension : la page les appelle en `/www/…`, et le dossier `www/` du dépôt `ife_webhome` les fournit sous `ife.eco`. Un dépôt rendu ailleurs, sans copie de ces images, affiche ses pages sans logo ni icônes.

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
2. Commiter, puis pousser `main`.
3. Créer sur GitHub l'étiquette `vX.Y.Z` et sa release.

Les sites prennent la nouvelle version à leur rendu suivant.
