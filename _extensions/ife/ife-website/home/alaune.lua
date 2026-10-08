-- À la une : grille asymétrique, trois cartes larges puis quatre plus courtes.
--
-- YAML (index.qmd):
--   extensions:
--     ife-website:
--       alaune:
--         items: "_index_jsons/alaune.json"
--
-- JSON: { "items": [ { "url", "image", "image_alt", "kicker", "title",
--                     "date", "authors", "excerpt", "type", "lang",
--                     "keywords", "source", "region" } ] }
-- `region` : un code (`"fr"`) ou une liste (`["fr", "de", "eu"]`).

local utils = require(
    quarto.utils.resolve_path("_modules/utils.lua"):gsub("%.lua$", "")
)
local components = require(
    quarto.utils.resolve_path("_modules/components.lua"):gsub("%.lua$", "")
)

local FEATURED_COUNT = 3

local function title_html(title, url)
    local text = utils.html_escape(title)
    if text == "" then return "" end
    local href = utils.to_str(url)
    if href == "" then
        return string.format('<h3 class="alaune__title">%s</h3>', text)
    end
    return string.format(
        '<h3 class="alaune__title"><a href="%s"%s>%s</a></h3>',
        utils.html_escape(href),
        utils.link_attrs(href),
        text
    )
end

local function chart_html(image, alt, url)
    local src = utils.to_str(image)
    if src == "" then return "" end
    local img = string.format(
        '<img src="%s" alt="%s" />',
        utils.html_escape(src),
        utils.html_escape(utils.to_str(alt))
    )
    local href = utils.to_str(url)
    if href ~= "" then
        img = string.format(
            '<a href="%s"%s>%s</a>',
            utils.html_escape(href),
            utils.link_attrs(href),
            img
        )
    end
    return string.format('<div class="alaune__chart">%s</div>', img)
end

local function head_html(item)
    local parts = {
        components.badge_type(utils.pick(item, "type", "kicker")),
        components.lang_chip(utils.pick(item, "lang")),
        components.pdf_icon(utils.pick(item, "url", 1)),
    }
    local nonempty = {}
    for _, part in ipairs(parts) do
        if part ~= "" then table.insert(nonempty, part) end
    end
    if #nonempty == 0 then return "" end
    return string.format(
        '<div class="alaune__head">%s</div>',
        table.concat(nonempty)
    )
end

local function create_item(item, opts)
    opts = opts or {}
    local featured = opts.featured
    local url = utils.pick(item, "url", 1)
    local title = utils.pick(item, "title", 3)
    local image = utils.pick(item, "image", "img", "cover", 2)
    local alt = utils.pick(item, "image_alt", "alt")
    if alt == "" then alt = title end

    local classes = { "alaune__item" }
    if featured then
        table.insert(classes, "alaune__item--featured")
    else
        table.insert(classes, "alaune__item--compact")
    end
    if opts.lead then
        table.insert(classes, "alaune__item--lead")
    end

    local excerpt_html = ""
    local chart = ""
    if featured then
        excerpt_html = utils.el(
            "p",
            "alaune__excerpt",
            utils.rich_inline(utils.pick(item, "excerpt", "subtitle", "description"))
        )
        chart = chart_html(image, alt, url)
    end

    local source_html = components.source_badge(
        utils.pick(item, "source"),
        item.region
    )
    if source_html ~= "" then
        source_html = string.format(
            '<div class="alaune__foot">%s</div>',
            source_html
        )
    end

    return string.format([[
        <article class="%s">
            %s
            %s
            %s
            %s
            %s
            %s
            %s
            %s
        </article>
    ]],
        table.concat(classes, " "),
        head_html(item),
        utils.el(
            "p",
            "alaune__date",
            utils.html_escape(utils.format_date_fr(utils.raw_pick(item, "date", "published")))
        ),
        title_html(title, url),
        excerpt_html,
        components.authors_html(
            utils.pick(item, "authors", "author"),
            "alaune__authors"
        ),
        chart,
        components.keywords_row(item.keywords),
        source_html
    )
end

local function row_html(items, featured)
    if #items == 0 then return "" end
    local cards = {}
    for i, item in ipairs(items) do
        table.insert(cards, create_item(item, {
            featured = featured,
            lead = featured and i == 1,
        }))
    end
    local modifier = featured and "featured" or "compact"
    return string.format(
        '<div class="alaune__row alaune__row--%s">%s</div>',
        modifier,
        table.concat(cards)
    )
end

return {
    ["alaune"] = function(args, kwargs, meta)
        local cfg = utils.block_config(meta, "alaune")
        if not cfg then
            return pandoc.Str("")
        end

        local featured, compact = {}, {}
        for i, item in ipairs(cfg.items) do
            if i <= FEATURED_COUNT then
                table.insert(featured, item)
            else
                table.insert(compact, item)
            end
        end

        local title = cfg.title
        if title == "" then title = "À la une" end

        local body = string.format([[
                <div class="alaune">
                    <div class="alaune__grid">
                        %s
                        %s
                    </div>
                </div>
        ]], row_html(featured, true), row_html(compact, false))

        local html = utils.section_html(
            utils.section_header_html(title, cfg.url, cfg.more_url, cfg.more_label),
            body
        )
        return pandoc.RawBlock("html", html)
    end
}
