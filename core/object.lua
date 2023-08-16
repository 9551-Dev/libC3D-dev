local str = require("common.string_util")

local function make_methods(child)
    local base__tostring

    return setmetatable({
        __build=function(obj)
            child = obj

            obj.__tostring_enabled = true

            local object_mt = getmetatable(obj) or {}

            base__tostring = object_mt.__tostring

            function object_mt.__tostring(self)
                return (self:get_type() or "UNTYPED_OBJECT") .. str.format_table__tostring(self) or base__tostring(self)
            end

            obj.__mt_reference = object_mt
            obj.__to_string    = object_mt.__tostring

            setmetatable(obj,object_mt)

            return obj
        end,
        get_type = function(this) return (getmetatable(child) or {__type="INHERITED_"..tostring(child)}).__type end,
        __set_tostring = function(this,toggle)
            if toggle then child.__tostring_enabled = toggle
            else
                child.__tostring_enabled = not child.__tostring_enabled
            end

            if child.__tostring_enabled then
                child.__mt_reference.__tostring = child.__to_string
            else
                child.__mt_reference.__tostring = nil
            end

            return child
        end
    },{__tostring = function() return "OBJECT_BUILDER->"..child:get_type() .. str.format_table__tostring(child) end})
end

return {new=function(child)
    return setmetatable(child,{__index=make_methods(child)})
end}