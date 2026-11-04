# quarto-ife

L'extension Quarto `quarto-ife` porte la charte du site de l'IFE : le format `ife-html`, qui dessine l'en-tête, le pied de page et le style des pages, et le type de projet `ife-website`, qui déclare les shortcodes des blocs de la page d'accueil. C'est la seule source de cette extension, et chaque dépôt du site en installe une version publiée.

## Contenu

- `_extensions/ife/ife/` fournit le format `ife-html`. `template.html` dessine l'en-tête et le pied de page, et `sass/` porte la charte et le rendu visuel.
- `_extensions/ife/ife-website/` définit le type de projet `ife-website`. Il pose le favicon et le bandeau cookies, et déclare les shortcodes des blocs, un fichier par bloc dans `home/`.

## Installer l'extension

Une version publiée est une étiquette `vX.Y.Z` du dépôt. L'extension s'installe à la racine d'un projet Quarto avec la version voulue, ici `v0.1.0`.

``` bash
quarto add ofceweb/quarto-ife@v0.1.0 --no-prompt
```

Quarto nomme le dossier d'installation d'après le propriétaire du dépôt GitHub : l'extension arrive dans `_extensions/ofceweb/`, qui se commite avec le projet.
