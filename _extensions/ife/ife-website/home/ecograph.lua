-- L'Ecograph : bannière unique, graphique en fond, CTA contour.
-- 0 item => section omise. Au-delà de 1, seul le premier est rendu.
--
-- YAML (index.qmd):
--   extensions:
--     ife-website:
--       ecograph:
--         items: "_index_jsons/ecograph.json"
--
-- JSON: { "items": [ { "number", "title", "date", "subtitle", "excerpt",
--                     "author", "cta_label", "cta_url", "image", "image_alt" } ] }

local utils = require(
    quarto.utils.resolve_path("_modules/utils.lua"):gsub("%.lua$", "")
)
local components = require(
    quarto.utils.resolve_path("_modules/components.lua"):gsub("%.lua$", "")
)

local function heading_text(item)
    local title = utils.pick(item, "title")
    if title ~= "" then return title end
    local number = utils.pick(item, "number")
    if number == "" then return "" end
    return "L'Ecograph n°" .. number
end

local function create_banner(item, level)
    local title = heading_text(item)
    local image = utils.pick(item, "image", "img", "cover")
    local alt = utils.pick(item, "image_alt", "alt")
    if alt == "" then alt = title end

    return string.format([[
        <section class="ife-band ife-band--cover ecograph">
            %s
            <div class="ife-band__inner">
                <div class="ife-band__content">
                    %s
                    %s
                    %s
                    %s
                    %s
                    %s
                </div>
            </div>
        </section>
    ]],
        utils.image_html(image, alt, "ife-band__media"),
        utils.el("h" .. level, "ecograph__title", utils.html_escape(title)),
        utils.el(
            "p",
            "ecograph__date",
            utils.html_escape(utils.format_date_fr(utils.pick(item, "date")))
        ),
        utils.el(
            "h" .. (level + 1),
            "ecograph__subtitle",
            utils.rich_inline(utils.pick(item, "subtitle"))
        ),
        utils.el(
            "p",
            "ecograph__excerpt",
            utils.rich_inline(utils.pick(item, "excerpt"))
        ),
        components.authors_html(
            utils.pick(item, "author"),
            "ecograph__author"
        ),
        components.cta_button(
            utils.pick(item, "cta_label"),
            utils.pick(item, "cta_url", "url"),
            "outline",
            "arrow"
        )
    )
end

return {
    ["ecograph"] = function(args, kwargs, meta)
        local cfg = utils.block_config(meta, "ecograph")
        if not cfg then
            return pandoc.Str("")
        end
        if #cfg.items == 0 then
            return pandoc.Str("")
        end
        return pandoc.RawBlock(
            "html",
            create_banner(cfg.items[1], utils.band_heading_level(meta))
        )
    end
}
