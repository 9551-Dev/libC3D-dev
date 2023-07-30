local object = require("core.object")

return {attach=function(BUS)
    local macro_registry_methods = {__index=object.new{}}

    local registry_data = setmetatable({entries={},entry_lookup={}},macro_registry_methods):__build()
    BUS.registry.macro_registry = registry_data

    return registry_data
end}