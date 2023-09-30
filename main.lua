local cmgr     = require("core.cmgr")
local bus      = require("core.bus")
local handlers = require("core.handlers")

local screen_init = require("core.graphics.screen_init")

local update_thread = require("core.threads.update_thread")
local event_thread  = require("core.threads.event_thread")
local resize_thread = require("core.threads.resize_thread")
local key_thread    = require("core.threads.key_thread")
local tudp_thread   = require("core.threads.tupd_thread")

local per_matrix = require("core.3D.matrice.perspective")

return function(ENV,libdir,...)
    local args = table.pack(...)
    local BUS = bus.register_bus(ENV)
    handlers.attach(ENV)
    BUS.instance.libdir = libdir

    local log = BUS.log

    BUS.plugin_internal = require("core.plugin.internal_api").init(BUS)
    log("[ Inicialized plugin api ]",log.info)

    local function start_execution(program,path,terminal,parent,ox,oy)

        log("[ Getting terminal info ]",log.info)
        local w,h = terminal.getSize()
        local ok = pcall(function()
            BUS.graphics.monitor = peripheral.getName(parent)
        end)
        if not ok then BUS.graphics.monitor = "term_object" end

        log("  Type: "..BUS.graphics.monitor,log.debug)

        local sw,sh = w*2,h*3

        log("  Init size: "..sw.."x"..sh,log.debug)
        BUS.perspective.matrix = per_matrix(sw/2,sh/2,
            BUS.perspective.near,
            BUS.perspective.far,
            BUS.perspective.FOV
        )
        log("Created perspective matrix",log.debug)
        BUS.graphics.w,BUS.graphics.h = sw,sh
        BUS.graphics.display_source = terminal
        BUS.graphics.display = screen_init.new(BUS)
        BUS.graphics.screen_parent = parent
        BUS.graphics.event_offset = vector.new(ox,oy)
        BUS.clr_instance.update_palette(terminal)
        BUS.instance.package.scenedir = fs.getDir(path) or ""
        BUS.instance.package.libdir   = libdir
        BUS.instance.package.scenepak = string.format(
            "/%s/modules/required/?.lua;/%s/?.lua;/rom/modules/main/?.lua",
            libdir,BUS.instance.package.scenedir
        )
        BUS.instance.package.libpak = string.format(
            "/%s/?.lua;/rom/modules/main/?.lua",
            libdir
        )
        BUS.instance.package.intpak = string.format(
            "/%s/?.lua;/rom/modules/main/?.lua",
            libdir
        )
        log("Updated BUS with new data",log.debug)

        BUS.log:dump()

        for x,y in ENV.utils.table.map_iterator(BUS.graphics.w,BUS.graphics.h) do
            BUS.graphics.buffer     [y][x] = colors.black
            BUS.graphics.data_buffer[y][x] = {
                depth = math.huge
            }
        end
        log("Filled screenbuffer",log.debug)

        ENV.package.path = BUS.instance.package.scenepak

        log("Attempting to load given program",log.info)
        if type(program[1]) == "function" then
            local program_main = setfenv(program[1],ENV)
            local ok,err = pcall(function()
                program_main(table.unpack(args,1,args.n))
            end)

            if ok then
                log("Succesfully loaded program",log.success)
            else
                log("Failed to init loaded program -> "..err,log.fatal)
                log:dump()
                return false,err
            end
        else
            log("Failed to load program -> "..program[2],log.fatal)
            log:dump()
            return false,program[2]
        end

        log:dump()

        if type(ENV.c3d.init) == "function" then
            log("Found c3d.init. re-registering plugins.",log.info)
            local ok,err = pcall(ENV.c3d.init,os.epoch("utc"))
            if not ok then
                log("[ C3D INIT LOAD ERROR ] -> "..err,log.error)
            end

            BUS.c3d.plugin.register()
            BUS.c3d.plugin.load_registered()
            BUS.c3d.plugin.refinalize()
            log("Successfuly registered plugins",log.success)
            log:dump()
        end

        local main   = update_thread.make(ENV,BUS,args)
        local event  = event_thread .make(ENV,BUS)
        local resize = resize_thread.make(ENV,BUS,function() return BUS.graphics.screen_parent end)
        local key_h  = key_thread   .make(ENV,BUS)
        local tudp   = tudp_thread  .make(ENV,BUS)
        log("Finished plugin loading.",log.success)

        log("[ Resuming and getting data from the loaded program ]",log.info)
        local ok,err = coroutine.resume(main)
        local err_thread

        log:dump()

        local load_error = false
        if ok then
            log("[ C3D INIT SUCCESSFUL ]",log.success)
            log("[ STARTING EXECUTION ]",log.info)
            log("",log.info)

            log:dump()

            ok,err,err_thread = cmgr.start(BUS,function()
                return BUS.running
            end,BUS.threads,main,event,resize,key_h,tudp)

            if not ok then
                local trace = "NO MORE INFO"
                if err_thread then trace = debug.traceback(err_thread) end

                log("[ A FATAL ERROR HAS OCCURED ] -> " .. tostring(err or ""):gsub("\n",""),log.fatal)
                for str in string.gmatch(trace:gsub("\t","%    "), "([^\n]+)") do
                    log(str,log.warn)
                end
                log("",log.info)
                log:dump()
            else
                log("[ C3D EXITED NORMALLY ]",log.success)
                return true
            end
            log:dump()
        else
            load_error = true
            local trace = debug.traceback(main)
            log("[ C3D INIT FAILED ] -> "..tostring(err or ""),log.fatal)
            for str in string.gmatch(trace:gsub("\t","%    "), "([^\n]+)") do
                log(str,log.warn)
            end
            log("",log.info)
            log:dump()
        end

        if parent.getGraphicsMode and parent.getGraphicsMode() then parent.setGraphicsMode(0) end

        if not ok and (BUS.triggers.overrides.errorhandler or ENV.c3d.errorhandler) then
            if (BUS.triggers.overrides.errorhandler or ENV.c3d.errorhandler)(err) then
                log("[ C3D -> goodbye. ]",log.info)
                log:dump()
                return false,err,load_error and main or err_thread
            end
        elseif not ok then
            log("[ C3D -> goodbye. ]",log.info)
            log:dump()
            return false,err,load_error and main or err_thread
        end

        log("",log.info)
        log("[ C3D -> goodbye. ]",log.info)
        log:dump()

        return true,"Fine"
    end

    log("[ Loading plugin api modules.. ]",log.info)
    ENV.c3d.plugin   = require("modules.plugin")  (BUS,ENV)
    ENV.c3d.registry = require("modules.registry")(BUS)
    log("[ Loading plugin api objects.. ]",log.info)
    BUS.object.registry_entry = require("core.objects.registry_entry").add(BUS)
    BUS.object.plugin         = require("core.objects.plugin")        .add(BUS)
    log("",log.info)

    log("[ Loading internal objects.. ]",log.info)
    ENV.c3d.plugin.load(require("core.objects.palette")         .add(BUS))
    ENV.c3d.plugin.load(require("core.objects.texture")         .add(BUS))
    ENV.c3d.plugin.load(require("core.objects.scene_object")    .add(BUS))
    ENV.c3d.plugin.load(require("core.objects.generic_shape")   .add(BUS))
    ENV.c3d.plugin.load(require("core.objects.camera")          .add(BUS))
    ENV.c3d.plugin.load(require("core.objects.imported_model")  .add(BUS))
    ENV.c3d.plugin.load(require("core.objects.vector")          .add(BUS))
    ENV.c3d.plugin.load(require("core.objects.animated_texture").add(BUS))
    ENV.c3d.plugin.load(require("core.objects.sprite_sheet")    .add(BUS))
    ENV.c3d.plugin.load(require("core.objects.raw_mesh")        .add(BUS))
    ENV.c3d.plugin.load(require("core.objects.material")        .add(BUS))
    ENV.c3d.plugin.load(require("core.objects.layout")          .add(BUS))
    ENV.c3d.plugin.load(require("core.objects.pipeline")        .add(BUS))
    BUS.plugin_internal.register_objects       ()
    BUS.plugin_internal.load_registered_objects()

    log("[ Loading internal modules.. ]",log.info)
    ENV.c3d.plugin.load(require("modules.timer")      (BUS))
    ENV.c3d.plugin.load(require("modules.event")      (BUS))
    ENV.c3d.plugin.load(require("modules.graphics")   (BUS))
    ENV.c3d.plugin.load(require("modules.keyboard")   (BUS))
    ENV.c3d.plugin.load(require("modules.mouse")      (BUS))
    ENV.c3d.plugin.load(require("modules.thread")     (BUS))
    ENV.c3d.plugin.load(require("modules.sys")        (BUS))
    ENV.c3d.plugin.load(require("modules.scene")      (BUS))
    ENV.c3d.plugin.load(require("modules.perspective")(BUS))
    ENV.c3d.plugin.load(require("modules.geometry")   (BUS))
    ENV.c3d.plugin.load(require("modules.shader")     (BUS))
    ENV.c3d.plugin.load(require("modules.camera")     (BUS))
    ENV.c3d.plugin.load(require("modules.pipeline")   (BUS))
    ENV.c3d.plugin.load(require("modules.vector")     (BUS))
    ENV.c3d.plugin.load(require("modules.interact")   (BUS))
    ENV.c3d.plugin.load(require("modules.mesh")       (BUS))
    ENV.c3d.plugin.load(require("modules.log")        (BUS))
    ENV.c3d.plugin.load(require("modules.palette")    (BUS))
    ENV.c3d.plugin.load(require("modules.model")      (BUS))
    BUS.plugin_internal.register_modules       ()
    BUS.plugin_internal.load_registered_modules()

    ENV.c3d.plugin.load(require("core.pipeline.macros.core.component_argument")(BUS))
    BUS.plugin_internal.register_macros()
    BUS.plugin_internal.load_registered_macros()

    ENV.c3d.plugin.load("core.pipeline.root",ENV.c3d.plugin.sign{from_file=true,component_prefix="__c3d_component_"})
    BUS.plugin_internal.register_components()
    BUS.plugin_internal.load_registered_components()

    require("modules.c3d")(BUS,ENV)

    return start_execution
end