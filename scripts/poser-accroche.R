# Pose sur des pages HTML figées l'accroche de la bande commune
# (docs/injection-bande.md) : la feuille et le script de /assets/ avant
# </head>, et un emplacement pour l'en-tête et pour le pied de page, que
# /assets/ife-band.js remplace au chargement.
#
# Le script insère du texte sans réécrire le HTML, et ne touche pas une page
# qui porte déjà l'accroche : un second passage ne change rien. Le script ne
# masque pas l'ancien en-tête des pages figées.
#
# Usage : Rscript scripts/poser-accroche.R <dossier>
#   traite tous les fichiers .html du dossier et de ses sous-dossiers.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1 || !dir.exists(args[[1]])) {
  stop("Usage : Rscript scripts/poser-accroche.R <dossier>", call. = FALSE)
}

HEAD <- paste0(
  '<link rel="stylesheet" href="/assets/ife-band.css" />',
  '<script src="/assets/ife-band.js" defer></script>'
)
HEADER <- '<div data-ife-band="header"></div>'
FOOTER <- '<div data-ife-band="footer"></div>'

# Insère `text` avant ou après la première correspondance de `pattern`.
insert_at <- function(html, pattern, text, after = FALSE) {
  m <- regexpr(pattern, html, ignore.case = TRUE, perl = TRUE)
  if (m == -1) return(NULL)
  pos <- if (after) m + attr(m, "match.length") else m
  paste0(substr(html, 1, pos - 1), text, substr(html, pos, nchar(html)))
}

poser <- function(path) {
  size <- file.size(path)
  html <- readChar(path, size, useBytes = TRUE)
  if (grepl("data-ife-band=", html, fixed = TRUE)) return("déjà posée")
  html <- insert_at(html, "</head>", HEAD)
  if (!is.null(html)) html <- insert_at(html, "<body[^>]*>", HEADER, after = TRUE)
  # Dernier </body> : un commentaire ou un script peut en contenir un avant.
  if (!is.null(html)) html <- insert_at(html, "</body>(?![\\s\\S]*</body>)", FOOTER)
  if (is.null(html)) return("ignorée : pas de <head> ou de <body>")
  con <- file(path, "wb")
  on.exit(close(con))
  writeChar(html, con, eos = NULL, useBytes = TRUE)
  "posée"
}

files <- list.files(args[[1]], pattern = "\\.html?$", recursive = TRUE, full.names = TRUE)
results <- vapply(files, poser, character(1))
for (i in seq_along(files)) cat(results[[i]], ":", files[[i]], "\n")
cat(sum(results == "posée"), "page(s) modifiée(s) sur", length(files), "\n")
