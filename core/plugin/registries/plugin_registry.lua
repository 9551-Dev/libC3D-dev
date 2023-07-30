return {attach=function(BUS)
    local registry_data = setmetatable({entries={},entry_lookup={}},{})
    BUS.registry.plugin_registry = registry_data

    return registry_data
end}