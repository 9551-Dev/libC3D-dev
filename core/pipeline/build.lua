return {init=function(BUS)
    return {build=function(pipeline)
        local component_registry = BUS.registry.component_registry

        local pipeline_data = {
            pipe = pipeline
        }

        local root_component = component_registry:get(component_registry:lookup("__c3d_pipeline_root_component"))

        error(root_component:apply_self(nil,pipeline_data))
    end}
end}