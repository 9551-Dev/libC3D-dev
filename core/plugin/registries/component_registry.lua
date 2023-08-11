local object = require("core.object")

local generic = require("common.generic")

local str = require("common.string_util")

return {attach=function(BUS)
    local log = BUS.log

    local component_registry_entry = {
        __index=object.new{
            add_macro = function(this,macro_id)
                local registry_id = generic.uuid4()

                local located_macro = macro_id and BUS.registry.macro_registry[macro_id]

                if located_macro then
                    this.macros[registry_id] = located_macro
                else
                    error(str.interpolate("Attempted to give component $<name> an invalid macro"){name=this.entry.name},2)
                end
            end
        },__tostring=function(self) return str.format_table__tostring(self) end
    }

    local component_registry_methods = {
        __index=object.new{
            set_entry = function(this,registry_entry,source_entry_point)
                log(str.interpolate("Created in component registry entry -> $<name>"){name=registry_entry.name},log.info)
                log:dump()

                local dat = {
                    macros = {},

                    entry       = registry_entry,
                    entry_point = source_entry_point
                }

                this.entries     [registry_entry.id]   = dat
                this.entry_lookup[registry_entry.name] = registry_entry.id

                return setmetatable(dat,component_registry_entry):__build()
            end,
            get = function(this,entry_id)
                local entry = this.entries[entry_id]

                return setmetatable(entry,component_registry_entry):__build()
            end
        },__tostring=function(self) return str.format_table__tostring(self) end
    }


    local registry_data = setmetatable({entries={},entry_lookup={}},component_registry_methods):__build()
    BUS.registry.component_registry = registry_data

    return registry_data
end}