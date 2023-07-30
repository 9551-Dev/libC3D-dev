return {attach=function(BUS)
    BUS.registry.plugin_registry = setmetatable({entries={},entry_lookup={}},{})
end}