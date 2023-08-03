local str = require("common.string_util")

local function make_methods(child)
    return setmetatable({
        __build=function(obj)
            child = obj
            return obj
        end,
        get_type = function() return (getmetatable(child) or {__type=tostring(child)}).__type or tostring(child) end,
    },{__tostring=function() return str.format_table__tostring(child) end})
end

return {new=function(child)
    return setmetatable(child,{__index=make_methods(child)})
end}