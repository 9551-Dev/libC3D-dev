local utils = require("common.generic")

local build_pipeline = require("core.pipeline.build")

return {add=function(BUS)

    local pipeline_builder = build_pipeline.init(BUS)

    return function()
        local pipeline = plugin.new("c3d:object->pipeline")

        function pipeline.register_objects()
            local object_registry = c3d.registry.get_object_registry()
            local pipeline_object = object_registry:new_entry("pipeline")

            pipeline_object:set_entry(c3d.registry.entry("render"),function() end)

            pipeline_object:set_entry(c3d.registry.entry("get_layout"),function(this)
                return this.layout.object
            end)

            pipeline_object:set_entry(c3d.registry.entry("compile"),function(self)
                local pipeline_build = pipeline_builder.build(self)

                pipeline.builds[#pipeline.builds+1] = pipeline_build
                pipeline.current_build              = pipeline_build
            end)

            pipeline_object:constructor(function(layout_source,id_override)
                local id = id_override or utils.uuid4()
                local object = {
                    layout={
                        object=layout_source
                    },
                    builds = {},
                    id=id
                }

                BUS.pipe.pipelines[id] = object

                return object
            end)
        end

        pipeline:register()
    end
end}
