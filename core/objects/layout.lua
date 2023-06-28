local parse = require("common.parser_util")

local FACE_ATTRIBUTE    = 1
local VERTEX_ATTRIBUTES = 2
local COUNT_IDENTIFIER  = "__n"

return {add=function(BUS)

    return function()
        local layout = plugin.new("c3d:object->layout")

        function layout.register_objects()
            local layout        = c3d.registry.get_object_registry()
            local layout_object = layout:new_entry("layout")

            layout_object:set_entry(c3d.registry.entry("add_vertex_attribute"),function(this,identifier,count,mapper)
                local name,sub_names = parse.layout_attributes(identifier,count)

                this.basic_properties[#this.basic_properties+1] = {
                    name         = name,
                    value_amount = count,
                    model_mapper = mapper,
                    sub_names    = sub_names,
                    type         = VERTEX_ATTRIBUTES
                }

                this.basic_properties.__n = this.basic_properties.__n + 1

                return this
            end)
            layout_object:set_entry(c3d.registry.entry("add_face_attribute"),function(this,identifier,count,mapper)
                local name,sub_names = parse.layout_attributes(identifier,count)

                this.basic_properties[#this.basic_properties+1] = {
                    name         = name,
                    value_amount = count,
                    model_mapper = mapper,
                    sub_names    = sub_names,
                    type         = FACE_ATTRIBUTE
                }

                this.basic_properties.__n = this.basic_properties.__n + 1

                return this
            end)
            layout_object:set_entry(c3d.registry.entry("drop_attribute"),function(this,name)
                for i=1,this.basic_properties.__n do
                    if this.basic_properties[i] then
                        table.remove(this.basic_properties,i)
                        break
                    end
                end
            end)

            layout_object:set_entry(c3d.registry.entry("generate"),function(this)
                -- generates the data getters for the pipeline

                return this
            end)

            layout_object:set_entry(c3d.registry.entry("cast_generic_shape_layout"),function(this,generic_shape)
                -- casts a generic_shape to the layout using the provided generators and the layout data for optimization
                local generated = {}
                local cast      = {generated=generated}

                local triangle_count = 0

                for k,v in pairs(this.basic_properties) do
                    if k ~= COUNT_IDENTIFIER then
                        local mapped_data = v.model_mapper:apply(generic_shape.geometry,3,v.value_amount)

                        triangle_count = math.max(triangle_count,#mapped_data)
                        generated[#generated+1] = mapped_data
                    end
                end

                _G.generated = generated
                _G.properties = this.basic_properties

                --[[
                    local render_data = [CASTED]
                    local face_datapoints = [CASTED]

                    for face=1,#triangles do
                        face_property_id = (i-1)*face_datapoints + 1;
                    end
                ]]

                return cast
            end)

            layout_object:constructor(function()
                return {
                    basic_properties = {__n=0},
                    generated        = {}
                }
            end)
        end

        layout:register()
    end
end}