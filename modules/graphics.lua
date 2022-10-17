local graphics = {}

local clr = require("common.color_util")
local tbl = require("common.table_util")

local rasterer = require("core.graphics.rasterize")
local scrender = require("core.graphics.screen_render")

local scene_renderer = require("core.scene_render")

return function(BUS)

    BUS.clr_instance = clr

    local sc_renderer = scrender.build(BUS,
        scene_renderer.create(BUS,rasterer.build(BUS))
    )

    function graphics.clear_buffer(c)
        local bg = BUS.graphics
        local buff = bg.buffer

        for y=1,bg.h do
            local buffy = buff[y]
            for x=1,bg.w do
                buffy[x] = c
            end
        end
    end

    function graphics.render_frame()
        sc_renderer.make_frame()
    end

    function graphics.get_bg()
        return BUS.graphics.bg_col
    end
    function graphics.set_bg(c)
        BUS.graphics.bg_col = c
    end

    function graphics.get_resolution()
        local b = BUS.graphics
        return b.w,b.h
    end

    function graphics.load_texture(image,settings)
        return BUS.object.texture.new(image,settings)
    end

    return graphics
end