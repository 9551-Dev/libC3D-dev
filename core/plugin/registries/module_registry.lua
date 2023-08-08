local object = require("core.object")

local generic = require("common.generic")
local str     = require("common.string_util")

local plugin_helper = require("core.plugin.helper")

return {attach=function(BUS)
    local log = BUS.log

    local module_registry_entry = {
        __index=object.new{
            set_entry=function(this,registry_entry,value)
                log(str.interpolate("Created new entry in module registry -> $<group> -> $<name>"){
                    group=this.__rest.name,
                    name =registry_entry.name
                },log.debug)

                plugin_helper.set_registry_entry(this,registry_entry,value)
            end,
        },__type="test",__tostring=function(self) return str.format_table__tostring(self) end
    }

    local module_registry_methods = {
        __index=object.new{
            new_entry=function(this,name)

                log(str.interpolate("Created new module registry entry -> $<name>"){name=name},log.info)
                log:dump()

                local id = generic.uuid4()

                local dat = {}
                dat.__rest = {name=name,entries={},entry_lookup=dat,name_lookup={}}

                this.entries[id] = dat
                this.entry_lookup[name] = id

                return setmetatable(dat,module_registry_entry):__build()
            end,
            get=function(this,id)
                local entry = this.entries[id]

                return setmetatable(entry,module_registry_entry):__build()
            end
        },__tostring=function(self) return str.format_table__tostring(self) end
    }

    local registry_data = setmetatable({entries={},entry_lookup={}},module_registry_methods):__build()
    BUS.registry.module_registry = registry_data

    _G.reg = registry_data

    return registry_data
end}