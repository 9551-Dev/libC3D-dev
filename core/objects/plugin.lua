local object = require("core.object")

local str = require("common.string_util")

return {add=function(BUS)

    local function attach_register(f,register_name,data)
        local plugin_env = setmetatable({
            [register_name]=data
        },{__index=BUS.ENV})

        ---@diagnostic disable deprecated-function
        return setfenv(f,plugin_env)
    end

    local function register_plugin_trigger(plugin,trigger_registry,access_point)
        if type(plugin[access_point]) == "function" then
            BUS.triggers[trigger_registry][#BUS.triggers[trigger_registry]+1] = plugin[access_point]
        end
    end

    local function register_loader(source,provider,register,registry_lookup)
        if type(source[provider]) == "function" then
            local entry_loader = attach_register(source[provider],"__reg",registry_lookup)
            BUS.plugin[register][source.order][source.id] = entry_loader
        end
    end

    local plugin_methods = {
        __index = object.new{
            register=function(this)
                BUS.log(str.interpolate("Registering plugin -> $<plugin_id>"){plugin_id=this.PLUGID},BUS.log.debug)
                BUS.log:dump()

                register_plugin_trigger(this,"frame_finished",  "frame_finished")
                register_plugin_trigger(this,"on_full_load",    "on_init_finish")
                register_plugin_trigger(this,"post_display",    "post_display")
                register_plugin_trigger(this,"post_frame",      "post_frame")
                register_plugin_trigger(this,"pre_frame",       "pre_frame")

                local registry_lookup = {
                    OBJECT    = BUS.registry.object_registry   .entry_lookup,
                    MODULE    = BUS.registry.module_registry   .entry_lookup,
                    THREAD    = BUS.registry.thread_registry   .entry_lookup,
                    MACRO     = BUS.registry.macro_registry    .entry_lookup,
                    COMPONENT = BUS.registry.component_registry.entry_lookup
                }

                register_loader(this,"register_objects","objects",registry_lookup)
                register_loader(this,"register_modules","modules",registry_lookup)
                register_loader(this,"register_threads","threads",registry_lookup)

                register_loader(this,"register_macros"    ,"macros",    registry_lookup)
                register_loader(this,"register_components","components",registry_lookup)
            end,
            set_load_order=function(this,n)
                this.order = n
            end,
            get_bus=function()
                return BUS
            end,
            get_plugin_bus=function(this)
                return this.bus
            end,
            override=function(this,tp,val)
                BUS.plugin.scheduled_overrides[this.order][tp] = val
            end
        },__tostring=function() return "plugin" end
    }

    return {new=function(id,registry_name)
        local allocated_bus = {}
        BUS.plugin.plugin_bus[registry_name] = allocated_bus

        local obj = {id=id,order=0,PLUGID=registry_name,bus=allocated_bus}

        BUS.registry.plugin_registry[registry_name] = id

        return setmetatable(obj,plugin_methods):__build()
    end}
end}