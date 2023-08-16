local object = require("core.object")

local str = require("common.string_util")

local plugin_helper = require("core.plugin.helper")

return {attach=function(BUS)
    local log = BUS.log

    local thread_registry_methods = {
        __index=object.new{
            set_entry=function(this,registry_entry,value)
                log(str.interpolate("$Created new thread registry entry -> <entry_name>"){entry_name=registry_entry.name},log.info)

                this.entries     [registry_entry.id]   = value
                this.entry_lookup[registry_entry.name] = registry_entry
                this.name_lookup [registry_entry.id]   = registry_entry.name
            end,
            bind = plugin_helper.bind
        },__tostring=function(self) return str.format_table__tostring(self) end
    }

    local registry_data = setmetatable({entries={},entry_lookup={},name_lookup={}},thread_registry_methods):__build()
    BUS.registry.thread_registry = registry_data

    return registry_data
end}