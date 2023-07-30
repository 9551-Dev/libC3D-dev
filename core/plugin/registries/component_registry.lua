local object = require("core.object")

return {attach=function(BUS)
    local component_registry_methods = {__index=object.new{}}


    local registry_data = setmetatable({entries={},entry_lookup={}},component_registry_methods):__build()
    BUS.registry.component_registry = registry_data

    return registry_data
end}