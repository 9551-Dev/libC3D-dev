local plugin = {}

local generic = require("common.generic")

local str = require("common.string_util")

local plugin_helper = require("core.plugin.helper")

return function(BUS,ENV)
    local registry_entry = require("core.objects.registry_entry").add(BUS)

    local file_reader = generic.make_package_file_reader(BUS.ENV.package)

    function plugin.load(source,settings,...)
        local args = table.pack(...)

        local plugin_env = setmetatable({},{__index=ENV})

        local reg_entry = registry_entry.new("[TEMPORARY]")

        local source_function,entry_points,string_source
        if type(settings) == "table" and settings.from_file and settings.__c3d_signature == BUS.signature then
            local source_string,source_path = file_reader.get_data_path(source)

            if type(settings.component_prefix) == "string" then
                source_string,entry_points = plugin_helper.patch_plugin_file(source_string,settings.component_prefix)

                for i=1,#entry_points do
                    plugin_env[entry_points[i]] = function(source)
                        if not BUS.plugin.component_sources[reg_entry.id] then
                            BUS.plugin.component_sources[reg_entry.id] = {}
                        end

                        BUS.plugin.component_sources[reg_entry.id][entry_points[i]] = source
                    end
                end
            end

            string_source = source_string

            source_function = load(source_string,str.interpolate("=$<path>"){path=source_path},"t",{})
        else
            source_function = source
        end

        local plugin_factory = {new=function(name)
            BUS.log("Created new plugin -> "..name,BUS.log.debug)
            BUS.log:dump()

            reg_entry.name = name

            return BUS.object.plugin.new(reg_entry,name,string_source,settings)
        end}

        plugin_env.plug   = plugin_factory
        plugin_env.plugin = plugin_factory

        local ok,err = pcall(function()
            local env_patched_code = setfenv(source_function,plugin_env)
            env_patched_code(table.unpack(args,1,args.n))
        end)

        if not ok then
            error("Error loading plugin: "..tostring(err),0)
        end
    end

    function plugin.register()
        BUS.plugin_internal.register_macros    ()
        BUS.plugin_internal.register_modules   ()
        BUS.plugin_internal.register_objects   ()
        BUS.plugin_internal.register_threads   ()
        BUS.plugin_internal.register_components()
    end

    function plugin.load_registered()
        BUS.plugin_internal.load_registered_macros    ()
        BUS.plugin_internal.load_registered_modules   ()
        BUS.plugin_internal.load_registered_objects   ()
        BUS.plugin_internal.load_registered_threads   ()
        BUS.plugin_internal.load_registered_components()
    end

    function plugin.refinalize()
        BUS.plugin_internal.finalize_load ()
        BUS.plugin_internal.load_overrides()
    end

    function plugin.sign(tbl)
        tbl.__c3d_signature = BUS.signature
        return tbl
    end

    return plugin
end