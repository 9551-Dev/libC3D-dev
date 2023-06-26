return function(BUS)

    return function()
        local pipe = plugin.new("c3d:module->pipeline")

        function pipe.on_init_finish()
            --[[local base_layout = BUS.object.layout.new()
                :add_vertex_attribute("position",3,BUS.c3d.model.map    ("vertices","tris"))
                :add_face_attribute  ("id",      1,BUS.c3d.model.provide("tris"           ))
            :generate()]]

            local base_layout = BUS.object.layout.new()
            :generate()

            BUS.pipe.default = BUS.object.pipeline.new(base_layout,BUS.pipe.default.id)
        end

        function pipe.register_modules()
            local module_registry = c3d.registry.get_module_registry()
            local pipe_module     = module_registry:new_entry("pipeline")

            pipe_module:set_entry(c3d.registry.entry("new"),function(...)
                return BUS.object.pipeline.new(...)
            end)

            pipe_module:set_entry(c3d.registry.entry("layout"),function(...)
                return BUS.object.layout.new(...)
            end)
        end

        pipe:register()
    end
end