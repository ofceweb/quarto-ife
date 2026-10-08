-- Nos outils : bandeau sombre, titre à gauche, cartes bordées à droite.
-- 0 item => section omise.
--
-- YAML (index.qmd):
--   extensions:
--     ife-website:
--       outils:
--         items: "_index_jsons/outils.json"
--
-- JSON: { "items": [ { "title", "description", "cta_label", "url" } ] }

local utils = require(
    quarto.utils.resolve_path("_modules/utils.lua"):gsub("%.lua$", "")
)
local components = require(
    quarto.utils.resolve_path("_modules/components.lua"):gsub("%.lua$", "")
)

local function create_card(item)
    local title = utils.pick(item, "title")
    local cta = utils.pick(item, "cta_label")
    if cta == "" then cta = title end

    return string.format([[
        <article class="outils__card">
            %s
            %s
            %s
        </article>
    ]],
        utils.el("h3", "outils__title", utils.html_escape(title)),
        utils.el(
            "p",
            "outils__description",
            utils.rich_inline(utils.pick(item, "description"))
        ),
        components.cta_button(
            cta,
            utils.pick(item, "url"),
            "outline",
            "arrow"
        )
    )
end

local function create_band(items, title)
    local cards_html = {}
    for _, item in ipairs(items) do
        table.insert(cards_html, create_card(item))
    end

    return string.format([[
        <section class="ife-band outils">
            <div class="ife-band__inner">
                %s
                <div class="outils__grid">
                    %s
                </div>
            </div>
        </section>
    ]],
        utils.el("h2", "outils__heading", utils.html_escape(title)),
        table.concat(cards_html)
    )
end

return {
    ["outils"] = function(args, kwargs, meta)
        local cfg = utils.block_config(meta, "outils")
        if not cfg then
            return pandoc.Str("")
        end
        if #cfg.items == 0 then
            return pandoc.Str("")
        end
        local title = cfg.title
        if title == "" then title = "Nos outils" end
        return pandoc.RawBlock("html", create_band(cfg.items, title))
    end
}
