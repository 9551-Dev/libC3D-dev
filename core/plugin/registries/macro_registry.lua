return {attach=function(BUS)

    BUS.registry.macro_registry = setmetatable({entries={},entry_lookup={}},macro_registry_methods):__build()
end}