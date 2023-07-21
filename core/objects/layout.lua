local parse = require("common.parser_util")
local tbl   = require("common.table_util")

local tampl = require("lib.tampl")

local FACE_ATTRIBUTE   = 1
local VERTEX_ATTRIBUTE = 2
local attribute_type_naming = {
    [FACE_ATTRIBUTE] = "c3d_face_attribute",
    [VERTEX_ATTRIBUTE] = "c3d_vertex_attribute"
}
local vertex_names = {"a","b","c"}

return {add=function(BUS)

    local function attribute_sorter(prop_a,prop_b)
        return prop_a.type < prop_b.type
    end
    local function generated_sorter(attr_a,attr_b)
        return attribute_sorter(attr_a.attributes,attr_b.attributes)
    end

    return function()
        local layout = plugin.new("c3d:object->layout")

        function layout.register_objects()
            local layout        = c3d.registry.get_object_registry()
            local layout_object = layout:new_entry("layout")

            layout_object:set_entry(c3d.registry.entry("add_vertex_attribute"),function(this,identifier,count,mapper)
                local name,sub_names = parse.layout_attributes(identifier,count)
                this:drop_attribute(name)

                this.layout_attributes[#this.layout_attributes+1] = {
                    name         = name,
                    value_amount = count,
                    model_mapper = mapper,
                    sub_names    = sub_names,
                    type         = VERTEX_ATTRIBUTE
                }

                this.layout_attributes.__n = this.layout_attributes.__n + 1

                return this
            end)
            layout_object:set_entry(c3d.registry.entry("add_face_attribute"),function(this,identifier,count,mapper)
                local name,sub_names = parse.layout_attributes(identifier,count)
                this:drop_attribute(name)

                this.layout_attributes[#this.layout_attributes+1] = {
                    name         = name,
                    value_amount = count,
                    model_mapper = mapper,
                    sub_names    = sub_names,
                    type         = FACE_ATTRIBUTE
                }

                this.layout_attributes.__n = this.layout_attributes.__n + 1

                return this
            end)
            layout_object:set_entry(c3d.registry.entry("drop_attribute"),function(this,name)
                for i=1,this.layout_attributes.__n do
                    if this.layout_attributes[i].name == name then
                        table.remove(this.layout_attributes,i)
                        break
                    end
                end
            end)

            local attribute_body = [=[
                --[[#attribute_getter]]
            ]=]

            layout_object:set_entry(c3d.registry.entry("generate"),function(this)
                -- generates the data getters for the pipeline

                return this
            end)

            layout_object:set_entry(c3d.registry.entry("cast_generic_shape_layout"),function(this,generic_shape)
                local generated = {}
                local cast      = {generated=generated}

                local triangle_count = 0

                for attribute_index=1,this.layout_attributes.__n do
                    local attribute = this.layout_attributes[attribute_index]

                    local mapped_data = attribute.model_mapper:apply(generic_shape.geometry,3,attribute.value_amount)
                    mapped_data.attributes = attribute

                    triangle_count = math.max(triangle_count,#mapped_data)
                    generated[attribute_index] = mapped_data
                end

                table.sort(generated,generated_sorter)

                local output_n = 1
                for triangle_index=1,triangle_count do
                    for attribute_index=1,this.layout_attributes.__n do
                        local generated_list = generated[attribute_index]
                        local property_data  = generated_list[triangle_index]
                        local attribute      = generated_list.attributes
                        if attribute.type == VERTEX_ATTRIBUTE then
                            for vertex_index=1,3 do
                                local vertex_data = property_data[vertex_index]
                                for data_index=1,#vertex_data do
                                    cast[output_n] = vertex_data[data_index]

                                    output_n = output_n + 1
                                end
                            end
                        elseif attribute.type == FACE_ATTRIBUTE then
                            for data_index=1,#property_data do
                                cast[output_n] = property_data[data_index]

                                output_n = output_n + 1
                            end
                        end

                    end
                end

                return cast
            end)

            layout_object:constructor(function()
                return {
                    layout_attributes = {__n=0},
                    generated        = {}
                }
            end)
        end

        layout:register()
    end
end}