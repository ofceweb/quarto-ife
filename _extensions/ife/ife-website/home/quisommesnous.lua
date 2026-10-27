-- Qui sommes-nous : bannière unique, image de fond, CTA blanc.
-- 0 item => section omise. Au-delà de 1, seul le premier est rendu.
--
-- YAML (index.qmd):
--   extensions:
--     ife-website:
--       quisommesnous:
--         items: "_index_jsons/quisommesnous.json"
--
-- JSON: { "items": [ { "title", "date", "subtitle", "excerpt",
--                     "cta_label", "cta_url", "image" } ] }
-- `image` est décorative (`alt=""`) : pas de champ `image_alt`.

local utils = require(
    quarto.utils.resolve_path("_modules/utils.lua"):gsub("%.lua$", "")
)
local components = require(
    quarto.utils.resolve_path("_modules/components.lua"):gsub("%.lua$", "")
)

local function create_banner(item, level)
    local title = utils.pick(item, "title")
    local image = utils.pick(item, "image", "img", "cover")

    return string.format([[
        <section class="ife-band ife-band--cover quisommesnous">
            %s
            <div class="ife-band__inner">
                <div class="ife-band__content">
                    %s
                    %s
                    %s
                    %s
                    %s
                </div>
            </div>
        </section>
    ]],
        utils.image_html(image, "", "ife-band__media", true),
        utils.el("h" .. level, "quisommesnous__title", utils.html_escape(title)),
        utils.el(
            "p",
            "quisommesnous__date",
            utils.html_escape(utils.format_date_fr(utils.pick(item, "date")))
        ),
        utils.el(
            "h" .. (level + 1),
            "quisommesnous__subtitle",
            utils.rich_inline(utils.pick(item, "subtitle"))
        ),
        utils.el(
            "p",
            "quisommesnous__excerpt",
            utils.rich_inline(utils.pick(item, "excerpt"))
        ),
        components.cta_button(
            utils.pick(item, "cta_label"),
            utils.pick(item, "cta_url"),
            "solid",
            "arrow"
        )
    )
end

return {
    ["quisommesnous"] = function(args, kwargs, meta)
        local cfg = utils.block_config(meta, "quisommesnous")
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
