local plugin = {}

local generic = require("common.generic")

local str = require("common.string_util")

local plugin_helper = require("core.plugin.helper")

return function(BUS,ENV)
    local file_reader = generic.make_package_file_reader(BUS.ENV.package)

    function plugin.load(source,settings,...)
        local args = table.pack(...)

        local id = generic.uuid4()

        local plugin_factory = {new=function(name)
            BUS.log("Created new plugin -> "..name,BUS.log.debug)
            BUS.log:dump()
            return BUS.object.plugin.new(id,name)
        end}

        local plugin_env = setmetatable({
            plug   = plugin_factory,
            plugin = plugin_factory
        },{__index=ENV})

        local source_function,entry_points
        if type(settings) == "table" and settings.from_file then
            local source_string,source_path = file_reader.get_data_path(source)

            if type(settings.component_prefix) == "string" then
                source_string,entry_points = plugin_helper.patch_plugin_file(source_string,settings.component_prefix)

                for i=1,#entry_points do
                    plugin_env[entry_points[i]] = function(source)
                        BUS.log(str.interpolate("Registered entrypoint $<entry> with source \n$<source>"){
                            entry  = entry_points[i],
                            source = source
                        })
                    end
                end
            end

            source_function = load(source_string,str.interpolate("=$<path>"){path=source_path},"t",{})
        else
            source_function = source
        end

        local ok,err = pcall(function()
            setfenv(source_function,plugin_env)(table.unpack(args,1,args.n))
        end)

        if not ok then
            error("Error loading plugin: "..tostring(err),0)
        end
    end

    function plugin.register()
        --BUS.plugin_internal.register_macros()
        BUS.plugin_internal.register_modules()
        BUS.plugin_internal.register_objects()
        BUS.plugin_internal.register_threads()
        --BUS.plugin_internal.register_components()
    end

    function plugin.load_registered()
        --BUS.plugin_internal.load_registered_macros()
        BUS.plugin_internal.load_registered_modules()
        BUS.plugin_internal.load_registered_objects()
        BUS.plugin_internal.load_registered_threads()
        --BUS.plugin_internal.load_registered_components()
    end

    function plugin.refinalize()
        BUS.plugin_internal.finalize_load ()
        BUS.plugin_internal.load_overrides()
    end

    return plugin
end