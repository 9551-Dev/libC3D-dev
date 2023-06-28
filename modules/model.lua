local object = require("core.object")

local strings = require("common.string_util")

return function(BUS)
    return function()
        local model = plugin.new("c3d:module->model")

        local objects = {
            mapper={__index=object.new{
                apply=function(self,model,group_size,block_size)
                    local data_size = self.data_size or block_size

                    local output = {}

                    local dataset = model[self.dataset_name]
                    local index   = model[self.index_name]

                    local group_count = #index/group_size

                    for group_index=1,group_count do
                        local current_group = {}
                        output[group_index] = current_group

                        local index_position = (group_index-1)*group_size

                        for i=1,group_size do
                            local data_group = {}

                            local index_location = index_position+i
                            local index_data = index[index_location]

                            local data_location  = (index_data-1)*data_size+1

                            for i=1,data_size do
                                local data_index = data_location+i-1

                                data_group[i] = dataset[data_index]
                            end


                            current_group[i] = data_group
                        end
                    end
                    return output
                end
            },__tostring=function(self) return "model_mapper"..strings.format_table__tostring(self) end},
            mapper_simple={__index=object.new{
                apply=function(self,model)
                    local output = {}

                    local dataset = model[self.dataset_name]
                    local index   = model[self.index_name]

                    local group_count = #index/self.group_size

                    for group_index=1,group_count do
                        local current_group = {}
                        output[group_index] = current_group

                        local index_position = (group_index-1)*self.group_size+1
                        for i=1,self.group_size do
                            local index_location = index_position+i-1
                            local index_data     = index  [index_location]
                            current_group[i]     = dataset[index_data]
                        end
                    end

                    return output
                end
            },__tostring=function(self) return "simple_model_mapper"..strings.format_table__tostring(self) end},
            provider={__index=object.new{
                apply=function(self,model)
                    local output     = {}
                    local model_data = model[self.source]

                    local data
                    if self.custom_data then
                        data = model[self.custom_data]
                    end

                    for i=1,#model_data/self.partition_size do
                        if data and data[i] then
                            output[i] = {data[i]}
                        else
                            output[i] = {i}
                        end
                    end

                    return output
                end
            },__tostring=function(self) return "model_key_provider"..strings.format_table__tostring(self) end},
            supplier={__index=object.new{
                apply=function(self)
                    return self.data
                end
            },__tostring=function(self) return "model_data_supplier"..strings.format_table__tostring(self) end},
            packer={__index=object.new{
                apply=function(self,model)
                    local output = {}

                    local data = model[self.source]
                    for data_begin=1,#data,self.group_size do
                        local data_block = {}
                        for data_offset=1,self.group_size do
                            local data_index = data_begin+data_offset - 1
                            data_block[data_offset] = data[data_index]
                        end
                        output[#output+1] = data_block
                    end

                    return output
                end
            },__tostring=function(self) return "model_data_packer"..strings.format_table__tostring(self) end}
        }

        function model.register_modules()
            local module_registry = c3d.registry.get_module_registry()
            local geometry_module = module_registry:new_entry("model")

            geometry_module:set_entry(c3d.registry.entry("object_registry"),objects)

            geometry_module:set_entry(c3d.registry.entry("load"),function(path)
                return BUS.object.imported_model.new(path)
            end)

            geometry_module:set_entry(c3d.registry.entry("map"),function(dataset,index,data_size)
                return setmetatable({
                    dataset_name = dataset,
                    index_name   = index,
                    data_size    = data_size
                },objects.mapper):__build()
            end)
            geometry_module:set_entry(c3d.registry.entry("map_simple"),function(dataset,index,group_size)
                return setmetatable({
                    dataset_name = dataset,
                    index_name   = index,
                    group_size   = group_size
                },objects.mapper_simple):__build()
            end)
            geometry_module:set_entry(c3d.registry.entry("provide"),function(source,partition_size,custom_data)
                return setmetatable({
                    source         = source,
                    partition_size = partition_size,
                    custom_data    = custom_data
                },objects.provider):__build()
            end)
            geometry_module:set_entry(c3d.registry.entry("supply"),function(data)
                return setmetatable({
                    data = data
                },objects.supplier):__build()
            end)
            geometry_module:set_entry(c3d.registry.entry("repack"),function(source,grouping_size)
                return setmetatable({
                    source     = source,
                    group_size = grouping_size
                },objects.packer):__build()
            end)
        end

        model:register()
    end
end