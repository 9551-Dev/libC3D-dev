local object = require("core.object")

local generic = require("common.generic")
local str     = require("common.string_util")

return {attach=function(BUS)
    local log = BUS.log

    local object_registry_entry = {
        __index=object.new{
            set_entry=function(this,registry_entry,value)
                log(str.interpolate("Created new entry in object registry -> $<group> -> $<name>"){
                        group=this.__rest.name,
                        name =registry_entry.name
                },log.debug)

                this.__rest.entries     [registry_entry.id] = value
                this.__rest.entry_lookup[registry_entry.name] = registry_entry
                this.__rest.name_lookup [registry_entry.id] = registry_entry.name
            end,
            set_metadata=function(this,name,val)
                rawset(this.__rest.metadata,name,val)
            end,
            constructor=function(this,constructor_method)
                this.__rest.constructor = constructor_method
            end,
            define_decoder=function(this,extension,decoder)
                this.__rest.file_handlers[extension] = decoder.read
            end,
            read_file=function(this,path,...)
                local extension = path:match("^.+(%..+)$")
                local file_path = fs.combine(BUS.instance.package.scenedir,path)

                if not this.__rest.file_handlers[extension] then
                    error("Tried to decode unsupported file format: "..tostring(extension or ""))
                end

                return this.__rest.file_handlers[extension](file_path,...)
            end
        },__tostring=function() return "object_registry_entry" end
    }

    local object_registry_methods = {
        __index=object.new{
            new_entry=function(this,name)

                log(str.interpolate("Created new object registry entry -> $<name>"){name=name})
                log:dump()

                local id = generic.uuid4()

                local dat = {}
                dat.__rest = {name=name,entries={},entry_lookup=dat,name_lookup={},metadata={},file_handlers={}}

                this.entries[id] = dat
                this.entry_lookup[name] = id

                return setmetatable(dat,object_registry_entry):__build()
            end,
            get=function(this,id)
                local entry = this.entries[id]

                return setmetatable(entry,object_registry_entry):__build()
            end
        },__tostring=function() return "object_registry" end
    }

    local registry_data = setmetatable({entries={},entry_lookup={}},object_registry_methods):__build()
    BUS.registry.object_registry = registry_data

    return registry_data
end}