local object = require("core.object")

local str = require("common.string_util")

local plugin_helper = require("core.plugin.helper")

return {attach=function(BUS)
    local log = BUS.log

    local macro_registry_entry = {
        __index=object.new{
        },__tostring=function(self) return str.format_table__tostring(self) end
    }

    local macro_registry_methods = {
        __index=object.new{
            set_entry = function(this,registry_entry,processor_function)
                log(str.interpolate("Created in macro registry entry -> $<name>"){name=registry_entry.name},log.info)
                log:dump()


                local dat = {
                    entry     = registry_entry,
                    processor = processor_function
                }

                this.entries     [registry_entry.id]   = dat
                this.entry_lookup[registry_entry.name] = registry_entry.id

                return setmetatable(dat,macro_registry_entry):__build()
            end,
            get = function(this,entry_id)
                local entry = this.entries[entry_id]

                return setmetatable(entry,macro_registry_entry):__build()
            end,
            bind = plugin_helper.bind
        },__tostring=function(self) return str.format_table__tostring(self) end
    }


    local registry_data = setmetatable({entries={},entry_lookup={}},macro_registry_methods):__build()
    BUS.registry.macro_registry = registry_data

    return registry_data
end}