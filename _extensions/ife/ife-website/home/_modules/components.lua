-- Primitives HTML partagées par les shortcodes de blocs (ife-website).
--
-- Les shortcodes appellent ces fonctions et assemblent le HTML de chaque
-- bloc. L'échappement et les dates passent par `_modules/utils.lua`.

local utils = require(
    quarto.utils.resolve_path("_modules/utils.lua"):gsub("%.lua$", "")
)

local components = {}

local ICONS = {
    arrow = "bi-arrow-right",
    envelope = "bi-envelope",
    pdf = "bi-file-earmark-pdf",
    calendar = "bi-calendar3",
    pin = "bi-geo-alt",
}

local SOURCE_LABELS = {
    ofce = "OFCE",
    cepii = "CEPII",
}

local VARIANTS = {
    solid = "solid",
    fill = "solid",
    primary = "solid",
    outline = "outline",
    ghost = "outline",
    light = "outline",
    ["outline-dark"] = "outline-dark",
    dark = "outline-dark",
}

--- Classe Bootstrap Icons (`bi bi-…`), chaîne vide si name est vide
--- @param name string|nil Clé courte (`arrow`) ou classe (`bi-arrow-right`)
--- @return string
local function bi_icon(name)
    local key = utils.to_str(name)
    if key == "" then return "" end
    local class_name = ICONS[key] or key
    if not class_name:match("^bi%-") then
        class_name = "bi-" .. class_name
    end
    return string.format('<i class="bi %s" aria-hidden="true"></i>', class_name)
end

--- Jeton CSS : minuscules, lettres, chiffres et tirets uniquement
--- @param value any
--- @return string
local function css_token(value)
    return utils.to_str(value):lower():gsub("[^a-z0-9%-]+", "")
end

--- @param source any
--- @return string `ofce`, `cepii`, ou jeton normalisé
local function source_key(source)
    local s = utils.to_str(source):lower()
    if s == "" then return "" end
    if s:find("cepii", 1, true) then return "cepii" end
    if s:find("ofce", 1, true) then return "ofce" end
    return css_token(s)
end

--- @param region any
--- @return string `fr`, `eu`, `world`, ou jeton normalisé
local function region_key(region)
    local s = utils.to_str(region):lower()
    if s == "" then return "" end
    if s == "fr" or s == "france" or s:match("^fr%-") then return "fr" end
    if s == "ue" or s == "eu" or s:find("europe", 1, true) then return "eu" end
    if s == "world" or s == "monde" or s == "intl"
        or s == "international" or s == "world-wide" then
        return "world"
    end
    return css_token(s)
end

--- Badge de type de contenu (Policy Brief, Séminaire, …). Omis si vide.
--- @param label string|nil
--- @return string
function components.badge_type(label)
    local text = utils.html_escape(utils.to_str(label))
    if text == "" then return "" end
    return string.format('<span class="ife-badge">%s</span>', text)
end

--- Chip de langue (`FR`, `EN`). Omis si vide.
--- @param lang string|nil
--- @return string
function components.lang_chip(lang)
    local text = utils.html_escape(utils.to_str(lang))
    if text == "" then return "" end
    return string.format('<span class="ife-lang-chip">%s</span>', text)
end

--- Lien icône PDF. Omis si l'URL est vide.
--- @param url string|nil
--- @return string
function components.pdf_icon(url)
    local href = utils.to_str(url)
    if href == "" then return "" end
    return string.format(
        '<a class="ife-pdf" href="%s"%s aria-label="Télécharger le PDF">%s</a>',
        utils.html_escape(href),
        utils.link_attrs(href),
        bi_icon("pdf")
    )
end

--- Badge de source OFCE / CEPII, drapeau optionnel (`fr`, `eu`/`ue`, `world`).
--- @param source string|nil
--- @param region string|nil
--- @return string
function components.source_badge(source, region)
    local key = source_key(source)
    if key == "" then return "" end
    local label = SOURCE_LABELS[key] or utils.html_escape(utils.to_str(source))
    local flag = ""
    local region_tok = region_key(region)
    if region_tok ~= "" then
        flag = string.format(
            '<span class="ife-source__flag ife-source__flag--%s" aria-hidden="true"></span>',
            region_tok
        )
    end
    return string.format(
        '<span class="ife-source ife-source--%s">%s%s</span>',
        key,
        flag,
        label
    )
end

--- Rangée de mots-clés. Accepte une liste ou une chaîne unique. Omis si vide.
--- @param keywords table|string|nil
--- @return string
function components.keywords_row(keywords)
    local items = {}
    if type(keywords) == "string" then
        local s = utils.to_str(keywords)
        if s ~= "" then table.insert(items, s) end
    elseif type(keywords) == "table" then
        for _, kw in ipairs(keywords) do
            local s = utils.to_str(kw)
            if s ~= "" then table.insert(items, s) end
        end
    end
    if #items == 0 then return "" end

    local lis = {}
    for _, kw in ipairs(items) do
        table.insert(lis, string.format(
            '<li class="ife-keywords__item">%s</li>',
            utils.html_escape(kw)
        ))
    end
    return string.format(
        '<ul class="ife-keywords">%s</ul>',
        table.concat(lis)
    )
end

--- Bouton d'action. Variantes : `solid`, `outline`, `outline-dark`.
--- `icon` : `arrow`, `envelope`, ou une classe Bootstrap Icons.
--- Omis si le libellé est vide. Sans URL, rend un `span`.
--- @param label string|nil
--- @param url string|nil
--- @param variant string|nil
--- @param icon string|nil
--- @return string
function components.cta_button(label, url, variant, icon)
    local text = utils.html_escape(utils.to_str(label))
    if text == "" then return "" end

    local variant_key = VARIANTS[utils.to_str(variant):lower()] or "solid"
    local icon_html = bi_icon(icon)
    local inner = text
    if icon_html ~= "" then
        inner = icon_html .. "<span>" .. text .. "</span>"
    end

    local class_name = "ife-btn ife-btn--" .. variant_key
    local href = utils.to_str(url)
    if href == "" then
        return string.format('<span class="%s">%s</span>', class_name, inner)
    end
    return string.format(
        '<a class="%s" href="%s"%s>%s</a>',
        class_name,
        utils.html_escape(href),
        utils.link_attrs(href),
        inner
    )
end

--- Titre de section, serif, sans filet. Omis si vide.
--- @param title string|nil
--- @return string
function components.section_title(title)
    local text = utils.html_escape(utils.to_str(title))
    if text == "" then return "" end
    return string.format('<h2 class="ife-section-title">%s</h2>', text)
end

--- Ligne de méta : badge de type, date (calendrier), lieu (épingle).
--- Omis si les trois champs sont vides. La date ISO est formatée en français.
--- @param type_label string|nil
--- @param date any
--- @param location string|nil
--- @return string
function components.meta_line(type_label, date, location)
    local parts = {}

    local badge = components.badge_type(type_label)
    if badge ~= "" then table.insert(parts, badge) end

    local date_text = utils.html_escape(utils.format_date_fr(date))
    if date_text ~= "" then
        table.insert(parts, string.format(
            '<span class="ife-meta__date">%s%s</span>',
            bi_icon("calendar"),
            date_text
        ))
    end

    local loc_text = utils.html_escape(utils.to_str(location))
    if loc_text ~= "" then
        table.insert(parts, string.format(
            '<span class="ife-meta__location">%s%s</span>',
            bi_icon("pin"),
            loc_text
        ))
    end

    if #parts == 0 then return "" end
    return string.format('<div class="ife-meta">%s</div>', table.concat(parts))
end

return components
