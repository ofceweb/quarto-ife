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
}

local SVG_ICONS = {
    envelope = "/www/mail_icon.svg",
}

local SOURCE_LABELS = {
    ofce = "OFCE",
    cepii = "CEPII",
}

local REGION_ICONS = {
    fr = "/www/fr_icon.svg",
    eu = "/www/eu_icon.svg",
    world = "/www/world_icon.svg",
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

--- Icône CTA : SVG du projet, sinon Bootstrap Icons. Chaîne vide si name est vide.
--- @param name string|nil Clé courte (`arrow`, `envelope`) ou classe (`bi-arrow-right`)
--- @return string
local function cta_icon(name)
    local key = utils.to_str(name)
    if key == "" then return "" end
    local src = SVG_ICONS[key]
    if src then
        return string.format(
            '<img src="%s" alt="" aria-hidden="true" />',
            src
        )
    end
    return bi_icon(key)
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

--- Marqueur PDF non cliquable. Affiché quand l'URL pointe un fichier .pdf,
--- pour signaler une publication disponible uniquement en PDF.
--- @param url string|nil URL principale de la publication
--- @return string
function components.pdf_icon(url)
    if not utils.to_str(url):lower():match("%.pdf$") then return "" end
    return '<span class="ife-pdf" aria-label="Disponible en PDF uniquement"><img src="/www/pdf_icon.svg" alt="" aria-hidden="true" /></span>'
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
    local icon_src = REGION_ICONS[region_key(region)]
    if icon_src then
        flag = string.format(
            '<img class="ife-source__flag" src="%s" alt="" aria-hidden="true" />',
            icon_src
        )
    end
    return string.format(
        '<span class="ife-source ife-source--%s">%s<span class="ife-source__label">%s</span></span>',
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
        '<ul class="ife-keywords"><li class="ife-keywords__icon" aria-hidden="true">%s</li>%s</ul>',
        bi_icon("arrow"),
        table.concat(lis)
    )
end

--- Bouton d'action. Variantes : `solid`, `outline`, `outline-dark`.
--- `icon` : `arrow` (Bootstrap), `envelope` (`mail_icon.svg`), ou une classe Bootstrap Icons.
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
    local icon_html = cta_icon(icon)
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

--- Ligne d'auteurs. Chaque nom porte `ife-author`. Omis si vide.
--- @param raw string|nil Chaîne unique, noms séparés par des virgules
--- @param class_name string Classe du paragraphe (`alaune__authors`, …)
--- @return string
function components.authors_html(raw, class_name)
    local text = utils.to_str(raw)
    if text == "" then return "" end
    local spans = {}
    for name in string.gmatch(text, "[^,]+") do
        local trimmed = name:match("^%s*(.-)%s*$")
        if trimmed ~= "" then
            table.insert(spans, string.format(
                '<span class="ife-author">%s</span>',
                utils.html_escape(trimmed)
            ))
        end
    end
    if #spans == 0 then return "" end
    return utils.el("p", class_name, table.concat(spans, ", "))
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
            '<span class="ife-meta__date"><img src="/www/calendar_icon.svg" alt="" aria-hidden="true" />%s</span>',
            date_text
        ))
    end

    local loc_text = utils.html_escape(utils.to_str(location))
    if loc_text ~= "" then
        table.insert(parts, string.format(
            '<span class="ife-meta__location"><img src="/www/localisation_icon.svg" alt="" aria-hidden="true" />%s</span>',
            loc_text
        ))
    end

    if #parts == 0 then return "" end
    return string.format('<div class="ife-meta">%s</div>', table.concat(parts))
end

return components
