-- Images du format et habillage de la page selon la marque.
--
-- Images : toutes les images que le format appelle vivent dans assets/img/.
-- Le filtre les déclare à Quarto comme fichiers d'une dépendance HTML sans
-- version, avec la feuille ife-images.css (masques des logos, plume de la
-- date). Quarto les copie une fois dans site_libs/quarto-contrib/ife-img/ du
-- site rendu, sans rien écrire dans le dépôt. Le filtre pose `ife-img`, que
-- les partials lisent ; Quarto rend relative à chaque page une adresse en
-- /site_libs/. Les blocs de l'accueil emploient le même chemin
-- (ife-website/home/_modules/components.lua).
--
-- Marque : `institution` dans _quarto.yml, ife (défaut), ofce pour IFE|OFCE,
-- cepii pour IFE|CEPII. Pour ofce et cepii, le filtre pose `ife-brand` et
-- `ife-brand-logo`, que template.html lit pour la classe de <body> et le
-- logo. Pour ife, il ne pose rien de plus : la page est celle de l'IFE.

local IMG = "/site_libs/quarto-contrib/ife-img"
local IMG_DIR = quarto.utils.resolve_path("assets/img")

local BRANDS = { "ife", "ofce", "cepii" }

local LOGOS = {
    ofce = IMG .. "/IFE-OFCE_logo_anthracite.svg",
    cepii = IMG .. "/IFE-CEPII_logo_anthracite.svg",
}

local function is_brand(value)
    for _, brand in ipairs(BRANDS) do
        if brand == value then return true end
    end
    return false
end

-- Fichiers de assets/img/, sous-dossiers compris, nommés par leur chemin
-- relatif à assets/img/ : c'est leur chemin dans le dossier de la dépendance.
local function list_images(dir, prefix, out)
    for _, name in ipairs(pandoc.system.list_directory(dir)) do
        local path = pandoc.path.join({ dir, name })
        local rel = prefix == "" and name or (prefix .. "/" .. name)
        local ok, entries = pcall(pandoc.system.list_directory, path)
        if ok and entries then
            list_images(path, rel, out)
        else
            table.insert(out, { name = rel, path = path })
        end
    end
    return out
end

local IMAGES = list_images(IMG_DIR, "", {})

function Meta(meta)
    quarto.doc.add_html_dependency({
        name = "ife-img",
        stylesheets = { "ife-images.css" },
        resources = IMAGES,
    })
    meta["ife-img"] = IMG

    if meta.institution == nil then return meta end
    local declared = pandoc.utils.stringify(meta.institution)
    local brand = declared:lower()
    if not is_brand(brand) then
        quarto.log.warning(
            "institution : valeur \"" .. declared .. "\" inconnue, habillage de l'IFE appliqué."
            .. " Valeurs admises : " .. table.concat(BRANDS, ", ") .. "."
        )
        return meta
    end
    if LOGOS[brand] == nil then return meta end
    meta["ife-brand"] = brand
    meta["ife-brand-logo"] = LOGOS[brand]
    return meta
end
