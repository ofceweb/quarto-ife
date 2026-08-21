-- Notre actualité : trois cartes avec image, puis trois lignes.
-- 0 item => section omise.
-- Les items `featured` forment les cartes (3 max). Les autres forment les
-- lignes (3 max), y compris le surplus de featured. Sans aucun `featured`,
-- les trois premiers items sont des cartes, les suivants des lignes.
--
-- YAML (index.qmd):
--   extensions:
--     ife-website:
--       actualite:
--         items: "_index_jsons/actualite.json"
--         more_url: "/evenements.html"
--         more_label: "Tous nos événements"
--
-- JSON: { "items": [ { "type", "title", "date", "location", "url",
--                     "image", "image_alt", "featured" } ] }

local utils = require(
    quarto.utils.resolve_path("_modules/utils.lua"):gsub("%.lua$", "")
)
local components = require(
    quarto.utils.resolve_path("_modules/components.lua"):gsub("%.lua$", "")
)

local CARD_COUNT = 3
local LINE_COUNT = 3

local function is_featured(item)
    local v = item.featured
    if v == true then return true end
    local s = utils.to_str(v):lower()
    return s == "true" or s == "1" or s == "yes"
end

local function take(list, n)
    local out = {}
    for i = 1, math.min(n, #list) do
        table.insert(out, list[i])
    end
    return out
end

local function slice(list, from_idx)
    local out = {}
    for i = from_idx, #list do
        table.insert(out, list[i])
    end
    return out
end

local function split_items(items)
    local flagged, others = {}, {}
    for _, item in ipairs(items) do
        if is_featured(item) then
            table.insert(flagged, item)
        else
            table.insert(others, item)
        end
    end
    if #flagged == 0 then
        return take(items, CARD_COUNT), take(slice(items, CARD_COUNT + 1), LINE_COUNT)
    end
    local cards = take(flagged, CARD_COUNT)
    local line_pool = slice(flagged, CARD_COUNT + 1)
    for _, item in ipairs(others) do
        table.insert(line_pool, item)
    end
    return cards, take(line_pool, LINE_COUNT)
end

local function title_html(title, url)
    local text = utils.html_escape(title)
    if text == "" then return "" end
    local href = utils.to_str(url)
    if href == "" then
        return string.format('<h3 class="actualite__title">%s</h3>', text)
    end
    return string.format(
        '<h3 class="actualite__title"><a href="%s"%s>%s</a></h3>',
        utils.html_escape(href),
        utils.link_attrs(href),
        text
    )
end

local function meta_html(item)
    return components.meta_line(
        utils.pick(item, "type"),
        utils.raw_pick(item, "date"),
        utils.pick(item, "location")
    )
end

local function create_card(item)
    local url = utils.pick(item, "url")
    local title = utils.pick(item, "title")
    local image = utils.pick(item, "image", "img", "cover")
    local alt = utils.pick(item, "image_alt", "alt")
    if alt == "" then alt = title end

    return string.format([[
        <article class="actualite__card">
            %s
            %s
            %s
        </article>
    ]],
        title_html(title, url),
        meta_html(item),
        utils.image_html(image, alt, "actualite__image")
    )
end

local function create_line(item)
    local url = utils.pick(item, "url")
    local title = utils.pick(item, "title")

    return string.format([[
        <article class="actualite__line">
            %s
            %s
        </article>
    ]],
        title_html(title, url),
        meta_html(item)
    )
end

local function list_html(items, create_fn, class_name)
    if #items == 0 then return "" end
    local parts = {}
    for _, item in ipairs(items) do
        table.insert(parts, create_fn(item))
    end
    return string.format(
        '<div class="%s">%s</div>',
        class_name,
        table.concat(parts)
    )
end

return {
    ["actualite"] = function(args, kwargs, meta)
        local cfg = utils.block_config(meta, "actualite")
        if not cfg then
            return pandoc.Str("")
        end
        if #cfg.items == 0 then
            return pandoc.Str("")
        end

        local cards, lines = split_items(cfg.items)

        local title = cfg.title
        if title == "" then title = "Notre actualité" end
        local more_label = cfg.more_label
        if more_label == "" then more_label = "Tous nos événements" end

        local body = string.format([[
                <div class="actualite">
                    %s
                    %s
                    <div class="actualite__more">
                        %s
                    </div>
                </div>
        ]],
            list_html(cards, create_card, "actualite__cards"),
            list_html(lines, create_line, "actualite__lines"),
            components.cta_button(more_label, cfg.more_url, "outline-dark")
        )

        local html = utils.section_html(
            utils.section_header_html(title, cfg.url),
            body
        )
        return pandoc.RawBlock("html", html)
    end
}
