local utils = require("common.generic")

local function build_pipeline()
    local FLOOR,CEIL = math.floor,math.ceil

    return function(this,model,w,h,cam_position,cam_rotation,cam_transform,matrix_perspective,pixel_draw)
        local cam_position,cam_rotation,cam_transform,matrix_perspective = cam_position,cam_rotation,cam_transform,matrix_perspective

        local geometry          = model.geometry
        local triangles_indices = geometry.tris
        local vertices          = geometry.vertices
        local triangle_count    = #triangles_indices

        -- model render data
        local model_transform = model.transform
    end
end

return {add=function(BUS)

    return function()
        local pipeline = plugin.new("c3d:object->pipeline")

        function pipeline.register_objects()
            local object_registry = c3d.registry.get_object_registry()
            local pipeline_object = object_registry:new_entry("pipeline")

            local base = build_pipeline()
            pipeline_object:set_entry(c3d.registry.entry("render"),base)

            pipeline_object:set_entry(c3d.registry.entry("get_layout"),function(this)
                return this.layout.object
            end)

            pipeline_object:constructor(function(layout_source,id_override)
                local id = id_override or utils.uuid4()
                local object = {
                    layout={
                        object=layout_source
                    },
                    id=id
                }

                BUS.pipe.pipelines[id] = object

                return object
            end)
        end

        pipeline:register()
    end
end}
