local object = require("core.object")

local str = require("common.string_util")

return {attach=function(BUS)
    local log = BUS.log

    local thread_registry_methods = {
        __index=object.new{
            set_entry=function(this,registry_entry,value)
                log(str.interpolate("Created new thread registry entry -> <entry_name>"){entry_name=registry_entry.name},log.info)

                this.entries     [registry_entry.id]   = value
                this.entry_lookup[registry_entry.name] = registry_entry
                this.name_lookup [registry_entry.id]   = registry_entry.name
            end,
        },__tostring=function() return "thread_registry" end
    }

    BUS.registry.thread_registry = setmetatable({entries={},entry_lookup={},name_lookup={}},thread_registry_methods):__build()
end}