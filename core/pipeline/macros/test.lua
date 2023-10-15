return function(BUS)
    return function()
        local test_macro = plugin.new("c3d:pipeline_macro->test")

        test_macro:set_load_order(-2)

        function test_macro.register_macros()
            local macro_registry = c3d.registry.get_macro_registry()

            macro_registry:set_entry(c3d.registry.entry("__c3d_pipeline_test_macro"),function(util,name)
                return util.compile(layout:get_getter())
            end)
        end

        test_macro:register()
    end
end