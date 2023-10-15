return {init=function(BUS)
    return {build=function(pipeline)
        local component_registry = BUS.registry.component_registry

        local pipeline_data = {
            pipe       = pipeline,
            layout_src = pipeline.layout,
            layout     = pipeline.layout.object,
            form       = pipeline.layout.object
        }

        local env_inject = {
            ref    = pipeline_data,
            layout = pipeline.layout.object,
        }

        local root_component = component_registry:get(component_registry:lookup("__c3d_pipeline_root_component"))

        error(root_component:apply_self(nil,{
            shared = pipeline_data,
            inject = env_inject
        }))
    end}
end}