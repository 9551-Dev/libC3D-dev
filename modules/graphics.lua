local graphics = {}

local clr = require("common.color_util")
local win = require("common.window_util")

local rasterer = require("core.graphics.rasterize")
local scrender = require("core.graphics.screen_render")
local sc_init  = require("core.graphics.screen_init")

local scene_renderer = require("core.scene_render")

local MAX,CEIL = math.max,math.ceil

return function(BUS)
    local _,update_perspective = require("modules.perspective")(BUS)

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

    function graphics.set_pixel_size(size)
        BUS.graphics.pixel_size = MAX(CEIL(size),1)
        update_perspective()
    end

    function graphics.get_stats()
        return BUS.graphics.stats
    end

    function graphics.autoresize(enable)
        BUS.graphics.auto_resize = enable
    end

    function graphics.set_size(w,h)
        BUS.graphics.w = w or BUS.graphics.w
        BUS.graphics.h = h or BUS.graphics.h

        update_perspective()
    end

    function graphics.change_terminal(term,resize)
        local init_win,ox,oy = win.get_parent_info(term)

        local terminal = window.create(term,1,1,term.getSize())

        BUS.graphics.event_offset = vector.new(ox,oy)
        BUS.clr_instance.update_palette(terminal)
        BUS.graphics.display_source = terminal
        BUS.graphics.display = sc_init.new(BUS)
        BUS.graphics.screen_parent = init_win

        local w,h = term.getSize()
        local ok = pcall(function()
            BUS.graphics.monitor = peripheral.getName(init_win)
        end)
        if not ok then BUS.graphics.monitor = "term_object" end

        if not resize then
            BUS.graphics.w = w
            BUS.graphics.h = h
        end

        update_perspective()
    end

    return graphics
end