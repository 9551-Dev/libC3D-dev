---@diagnostic disable: undefined-global

local __root__component = plugin.new("c3d:pipeline_component->__root__")

__root__component:set_load_order(-1)

function __root__component.register_components(this)
    --error(this)
    local component_registry = c3d.registry.get_component_registry()

    local __root__ = component_registry:set_entry(c3d.registry.entry("__c3d_pipeline_root_component"),{code_source=this})

    __root__:add_macro(c3d.registry.get_macro_registry():get(__reg.MACRO.__c3d_pipeline_test_macro),"TEST")
end

__c3d_register__c3d_pipeline_root_component(function()
    print("Pipeline root")

    TEST()
end)

__root__component:register()