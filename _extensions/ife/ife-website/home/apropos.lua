-- À propos : bandeau 409px, image en fond, texte empilé à gauche.
-- 0 item => section omise. Au-delà de 1, seul le premier est rendu.
--
-- YAML (index.qmd):
--   extensions:
--     ife-website:
--       apropos:
--         items: "_index_jsons/apropos.json"
--
-- JSON: { "items": [ { "title", "text", "contact_email",
--                     "image", "image_alt" } ] }

local utils = require(
    quarto.utils.resolve_path("_modules/utils.lua"):gsub("%.lua$", "")
)
local components = require(
    quarto.utils.resolve_path("_modules/components.lua"):gsub("%.lua$", "")
)

local function mailto_href(email)
    if email == "" then return "" end
    if email:match("^mailto:") then return email end
    return "mailto:" .. email
end

local function contact_label(email)
    if email == "" then return "" end
    return "Nous contacter :"
end

local function email_label(email)
    if email == "" then return "" end
    return email:gsub("^mailto:", "")
end

local function create_banner(item, level)
    local title = utils.pick(item, "title")
    local image = utils.pick(item, "image", "img", "cover")
    local email = utils.pick(item, "contact_email", "email")

    return string.format([[
        <section class="ife-band ife-band--cover apropos">
            %s
            <div class="ife-band__inner">
                <div class="ife-band__content">
                    <div class="apropos__intro">
                        %s
                        %s
                    </div>
                    <div class="apropos__contact">
                        %s
                        %s
                    </div>
                </div>
            </div>
        </section>
    ]],
        utils.image_html(image, "", "ife-band__media", true),
        utils.el("h" .. level, "apropos__title", utils.html_escape(title)),
        utils.el(
            "p",
            "apropos__text",
            utils.rich_inline(utils.pick(item, "text"))
        ),
        utils.el(
            "h" .. (level + 1),
            "apropos__contact-title",
            contact_label(email)
        ),
        components.cta_button(
            email_label(email),
            mailto_href(email),
            "outline",
            "envelope",
            "Écrire à "
        )
    )
end

return {
    ["apropos"] = function(args, kwargs, meta)
        local cfg = utils.block_config(meta, "apropos")
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
