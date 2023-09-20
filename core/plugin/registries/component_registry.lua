local object = require("core.object")
local macro  = require("core.macro")

local generic = require("common.generic")
local str     = require("common.string_util")

local plugin_helper = require("core.plugin.helper")

local code_formatter = require("lib.format_code")

return {attach=function(BUS)
    local log = BUS.log

    local component_registry_entry = {
        __index=object.new{
            add_macro = function(this,macro_entry,entry_point)
                local registry_id = generic.uuid4()

                if macro_entry then
                    this.macros[registry_id] = {
                        data        = macro_entry,
                        entry_point = entry_point
                    }
                else
                    error(str.interpolate("Attempted to give component $<name> an invalid macro"){name=this.entry.name},2)
                end
            end,
            gib_source_pls_im_beggig_yuo = function(this)
                local plugin_sources = BUS.plugin.component_sources[this.source_plugin_id]
                local plugin_object  = this.source_plugin

                return code_formatter.format(plugin_sources[
                    str.interpolate("$<prefix>$<entry_point>"){
                        prefix      = plugin_object.component_prefix,
                        entry_point = this.entry.name
                    }
                ])
            end,
            apply_self = function(this)
                return this.__apply_source(BUS.plugin.loaded_sources[this.entry.id])
            end,
            __apply_source = function(this,code)
                do
                    --local component_macros = macro.from_bus(BUS,this.macros)


                    --macro.process(code,component_macros)
                end
            end
        },__tostring=function(self) return str.format_table__tostring(self) end
    }

    local component_registry_methods = {
        __index=object.new{
            set_entry = function(this,registry_entry,settings)
                log(str.interpolate("Created in component registry entry -> $<name>"){name=registry_entry.name},log.info)
                log:dump()

                local dat = {
                    macros = {},

                    source_plugin_id = settings.code_source,
                    source_plugin    = BUS.registry.plugin_registry.entries[settings.code_source],

                    entry  = registry_entry,
                }

                this.entries     [registry_entry.id]   = dat
                this.entry_lookup[registry_entry.name] = registry_entry.id

                return setmetatable(dat,component_registry_entry):__build()
            end,
            get = function(this,entry_id)
                local entry = this.entries[entry_id]

                if not entry then
                    error("Couldnt get component registry entry. Entry does not exist. ",2)
                end

                return setmetatable(entry,component_registry_entry):__build()
            end,
            bind = plugin_helper.bind
        },__tostring=function(self) return str.format_table__tostring(self) end
    }


    local registry_data = setmetatable({entries={},entry_lookup={}},component_registry_methods):__build()
    BUS.registry.component_registry = registry_data

    return registry_data
end}