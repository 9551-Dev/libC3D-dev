local object = require("core.object")

local generic = require("common.generic")

local str = require("common.string_util")

return {add=function(BUS)

    local registry_entry_methods = {
        __index = object.new{
        },__tostring=function(self) return str.format_table__tostring(self) end,
        __type="registry_entry"
    }

    return {new=function(name,flags)
        if type(flags) ~= "table" then flags = {} end

        local obj = {
            id   = generic.uuid4(),
            name = name,

            forceful_override = flags.override
        }

        return setmetatable(obj,registry_entry_methods):__build()
    end}
end}