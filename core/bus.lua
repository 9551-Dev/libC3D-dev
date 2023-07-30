local init_registries = require("core.plugin.load_registries")

return {register_bus=function(ENV)
    local BUS = {
        timer={last_delta=0,temp_delta=0},
        c3d=ENV.c3d,
        ENV=ENV,
        frames={},
        events={},
        running=true,
        debug=false,
        graphics={
            buffer     =ENV.utils.table.createNDarray(1),
            data_buffer=ENV.utils.table.createNDarray(1),
            bg_col=colors.black,
            pixel_size=1,
            stats={
                frames_drawn=0,
            },
            auto_resize=true
        },
        pipe = {
            default   = {id=ENV.utils.generic.uuid4()},
            pipelines = {}
        },
        thread={
            channel={},
            coro={}
        },
        mouse={
            last_x=0,
            last_y=0,
            held={}
        },
        keyboard={
            pressed_keys={},
            textinput=true
        },
        instance={package={}},
        object={},
        threads={},
        sys={
            frame_time_min=0,
            init_time=os.epoch("utc"),
            run_time=0,
            autorender=true
        },
        perspective={
            near=0.1,
            far =1000,
            FOV =50
        },
        interactions={
            running=true,
            map=ENV.utils.table.createNDarray(1)
        },
        plugin={
            macros    =ENV.utils.table.createNDarray(1),
            modules   =ENV.utils.table.createNDarray(1),
            objects   =ENV.utils.table.createNDarray(1),
            threads   =ENV.utils.table.createNDarray(1),
            components=ENV.utils.table.createNDarray(1),

            scheduled_overrides=ENV.utils.table.createNDarray(1),

            plugin_bus={}
        },
        registry={
            macro_registry     = setmetatable({},{__tostring=function() return "thread_registry"    end}),
            module_registry    = setmetatable({},{__tostring=function() return "module_registry"    end}),
            plugin_registry    = setmetatable({},{__tostring=function() return "plugin_registry"    end}),
            object_registry    = setmetatable({},{__tostring=function() return "object_registry"    end}),
            thread_registry    = setmetatable({},{__tostring=function() return "thread_registry"    end}),
            component_registry = setmetatable({},{__tostring=function() return "component_registry" end})
        },
        triggers={
            overrides       ={},
            event_listeners ={},
            paused_listeners={},

            on_full_load  ={},
            post_frame    ={},
            frame_finished={},
            pre_frame     ={},
            post_display  ={}
        },
        scene={},
        camera={},
        animated_texture={instances={}},
        mem={},
        m_n=0
    }

    local log = require("lib.logger").create_log(BUS)

    BUS.log = log

    log("[-- Starting C3D --]",log.info)
    log("[ Loaded data bus ]",log.success)

    local seen = {[BUS.log]=true,[BUS.c3d]=true,[BUS.ENV]=true}

    local function printout(dist,val)
        log:dump()
        for k,v in pairs(val) do
            if type(v) == "table" and not seen[v] then
                log((" "):rep(dist).."|"..k..("("..tostring(v)..")"),log.debug)
                seen[v] = true
                printout(dist+1,v)
            else
                log((" "):rep(dist).."|"..k.." -> "..tostring(v),log.debug)
            end
        end
        if next(val) then log("",log.debug) end
    end
    printout(1,BUS)
    log("",log.info)

    init_registries.for_bus(BUS)

    log("[ Loaded plugin system ]",log.success)
    log("")

    log:dump()

    return BUS
end}