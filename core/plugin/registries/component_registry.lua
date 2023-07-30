local object = require("core.graphics")

return {attach=function(BUS)

    BUS.registry.component_registry = setmetatable({entries={},entry_lookup={}},component_registry_methods):__build()
end}