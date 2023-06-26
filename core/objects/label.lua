return {add=function(BUS)

    return function()
        local label = plugin.new("c3d:object->label")

        function label.register_objects()
            local label        = c3d.registry.get_object_registry()
            local label_object = label:new_entry("label")


            label_object:constructor(function()
                return {
                    vertex_properties = {},
                    face_properties   = {},
                    generated         = {}
                }
            end)
        end

        label:register()
    end
end}