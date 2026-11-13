// Bande commune de l'IFE : remplace, au chargement de la page, l'en-tête et le
// pied de page écrits au rendu par ceux de ce fichier, servi par le site en
// /assets/ife-band.js. Une modification atteint ainsi toutes les pages sans
// nouveau rendu. Si ce fichier ne répond pas, la page garde sa bande écrite au
// rendu, qui sert de repli. Voir docs/injection-bande.md.
//
// Source de /assets/ife-band.js : scripts/build-assets.sh y place le fragment
// tiré de html/header.html et html/footer.html.
(function () {
  "use strict";

  var FRAGMENT = String.raw`
__IFE_BAND_FRAGMENT__
`;

  // Logo de la marque, lu sur <body> (classe posée par brand.lua). La bande
  // commune porte le logo de l'IFE ; une page IFE|OFCE ou IFE|CEPII garde le sien.
  var LOGOS = {
    ofce: "/assets/img/IFE-OFCE_logo_anthracite.svg",
    cepii: "/assets/img/IFE-CEPII_logo_anthracite.svg"
  };

  function brandLogo() {
    for (var brand in LOGOS) {
      if (document.body.classList.contains("ife-brand--" + brand)) return LOGOS[brand];
    }
    return null;
  }

  // Bande écrite au rendu, ou accroche posée sur une page figée.
  function target(part) {
    return document.querySelector(part + ".ife-" + part) ||
      document.querySelector('[data-ife-band="' + part + '"]');
  }

  function inject() {
    var fragment = new DOMParser().parseFromString(FRAGMENT, "text/html");
    var header = fragment.querySelector("header.ife-header");
    var footer = fragment.querySelector("footer.ife-footer");
    if (!header || !footer) return;

    var logo = brandLogo();
    if (logo) {
      [header, footer].forEach(function (part) {
        var img = part.querySelector(".ife-lockup__logo");
        if (img) img.setAttribute("src", logo);
      });
    }

    var oldHeader = target("header");
    var oldFooter = target("footer");
    if (oldHeader) oldHeader.replaceWith(document.adoptNode(header));
    if (oldFooter) oldFooter.replaceWith(document.adoptNode(footer));
  }

  // Bouton du menu mobile, par délégation, pour une page figée qui n'a pas le
  // script de template.html. Une page rendue avec quarto-ife l'a déjà branché.
  function bindMenu() {
    if (window.ifeNavBound) return;
    window.ifeNavBound = true;
    function setOpen(header, toggle, open) {
      header.classList.toggle("is-open", open);
      toggle.setAttribute("aria-expanded", open ? "true" : "false");
      toggle.setAttribute("aria-label", open ? "Fermer le menu" : "Ouvrir le menu");
      var icon = toggle.querySelector("i");
      if (icon) {
        icon.classList.toggle("bi-list", !open);
        icon.classList.toggle("bi-x-lg", open);
      }
    }
    document.addEventListener("click", function (e) {
      var toggle = e.target.closest && e.target.closest(".ife-nav-toggle");
      var header = toggle && toggle.closest("header.ife-header");
      if (!header) return;
      setOpen(header, toggle, !header.classList.contains("is-open"));
    });
    // Échap ferme le menu et rend le focus au bouton.
    document.addEventListener("keydown", function (e) {
      var header = document.querySelector("header.ife-header");
      if (e.key !== "Escape" || !header || !header.classList.contains("is-open")) return;
      var toggle = header.querySelector(".ife-nav-toggle");
      if (!toggle) return;
      setOpen(header, toggle, false);
      toggle.focus();
    });
  }

  function run() {
    try {
      inject();
      bindMenu();
    } catch (e) {
      // Repli silencieux : la bande écrite au rendu reste en place.
    }
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", run);
  } else {
    run();
  }
})();
