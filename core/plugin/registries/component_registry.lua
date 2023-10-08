local object         = require("core.object")
local macro_provider = require("core.macro")

local generic = require("common.generic")
local str     = require("common.string_util")

local plugin_helper = require("core.plugin.helper")

local code_formatter = require("lib.format_code")

return {attach=function(BUS)
    local log = BUS.log

    local macro = macro_provider(BUS)

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

                return this
            end,
            add_component=function(this,component_entry,entry_point)
                local registry_id = generic.uuid4()

                if component_entry then
                    this.components[registry_id] = {
                        data        = component_entry,
                        entry_point = entry_point
                    }
                else
                    error(str.interpolate("Attempted to give component $<name> an invalid sub-component"){name=this.entry.name},2)
                end

                return this
            end,
            add_argument=function(this,name)
                this.arguments[#this.arguments+1] = name

                return this
            end,
            autoconfig=function(this)
                local source_code = this:__get_source()

                local arguments = source_code.arguments
                for k,v in ipairs(arguments) do
                    this:add_argument(v)
                end

                return this
            end,
            apply_self = function(this,parent,shared)
                local source_code = this:__get_source()

                return this:__apply_source(source_code.code,parent,shared),nil
            end,
            __apply_source = function(this,source_code,parent,shared)
                local source_buffer = source_code

                local instance_identifier = generic.uuid4()

                this.current_instance = instance_identifier
                this.parent           = parent
                this.shared           = (parent or {}).shared or shared

                this.instance_data[instance_identifier] = {
                    arguments = {}
                }

                do
                    local localized_macros = plugin_helper.quick_macro(BUS,this,this.macros)

                    source_buffer = macro.process(source_buffer,localized_macros)
                end

                local localized_components = plugin_helper.quick_components(BUS,this)

                local final = macro.process(source_buffer,localized_components)

                this.parent = nil

                return final
            end,
            __get_source = function(this)
                local plugin_sources = BUS.plugin.component_sources[this.source_plugin_id]
                local plugin_object  = this.source_plugin

                local source_identifier = str.interpolate("$<prefix>$<entry_point>"){
                    prefix      = plugin_object.component_prefix,
                    entry_point = this.entry.name
                }

                local source_code = plugin_sources[source_identifier]

                if not source_code then
                    error("Unable to locate source under " .. source_identifier.. " for " .. plugin_object.source_path,0)
                end

                return source_code
            end
        },__tostring=function(self) return str.format_table__tostring(self) end
    }

    local component_registry_methods = {
        __index=object.new{
            set_entry = function(this,registry_entry,settings)
                log(str.interpolate("Created new component registry entry -> $<name>"){name=registry_entry.name},log.info)
                log:dump()

                local dat = {
                    macros     = {},
                    components = {},

                    instance_data = {},

                    arguments = {},

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
            lookup = function(this,name)
                return this.entry_lookup[name]
            end,
            bind = plugin_helper.bind
        },__tostring=function(self) return str.format_table__tostring(self) end
    }


    local registry_data = setmetatable({entries={},entry_lookup={}},component_registry_methods):__build()
    BUS.registry.component_registry = registry_data

    return registry_data
end}