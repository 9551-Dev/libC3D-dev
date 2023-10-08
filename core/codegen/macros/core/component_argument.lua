return function(BUS)
    return function()
        local argument_macro = plugin.new("c3d:core_macro->component_argument")

        argument_macro:set_load_order(-2)

        function argument_macro.register_macros()
            local macro_registry = c3d.registry.get_macro_registry()

            macro_registry:set_entry(c3d.registry.entry("__c3d_core_argument_macro"),function(util,name)
                local parent_component = util.data.all.parent
                local this_component   = util.data.all

                local id_lookup = this_component.arguments

                local call_args = parent_component.instance_data[parent_component.current_instance].arguments

                local real_name = util:load_value(name.data)

                local observed_arg
                for i=1,#id_lookup do
                    if id_lookup[i] == real_name then
                        observed_arg = i
                        break
                    end
                end

                if observed_arg and not call_args[observed_arg] then
                    error("Tried to get argument \"" .. real_name .. "\" which was not provided in call",2)
                end
                if not observed_arg then
                    error("Tried to get argument \"" .. real_name .. "\" which does not exist",2)
                end

                return util.compile(call_args[observed_arg])
            end)
        end

        argument_macro:register()
    end
end