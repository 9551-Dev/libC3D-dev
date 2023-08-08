local str = require("common.string_util")

local function make_methods(child)
    return setmetatable({
        __build=function(obj)
            child = obj

            local object_mt = getmetatable(obj) or {}

            function object_mt.__tostring(self)
                return self:get_type() .. str.format_table__tostring(self)
            end

            setmetatable(obj,object_mt)

            return obj
        end,
        get_type  = function() return (getmetatable(child) or {__type=tostring(child)}).__type end,
    },{__tostring = function() return "OBJECT_BUILDER->"..child:get_type() .. str.format_table__tostring(child) end})
end

return {new=function(child)
    return setmetatable(child,{__index=make_methods(child)})
end}