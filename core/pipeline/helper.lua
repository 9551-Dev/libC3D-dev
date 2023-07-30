local object = require("core.object")

local string_util = require("common.string_util")

return {init=function(BUS)
    local candidates = {
        components = {},
        macros     = {}
    }

    local candidate_object = {__index=object.new{
    },__tostring=string_util.format_table__tostring}

    local function add_macro_candidate(path,identifier)
        table.insert(candidates.macros,setmetatable({
            path       = path,
            identifier = identifier
        },candidate_object):__build())
    end
    local function add_component_candidate(path,name)
        table.insert(candidates.components,setmetatable({
            path       = path,
            identifier = name
        },candidate_object):__build())
    end

    local function get_macro_candidates()
        return candidates.macros
    end
    local function get_component_candidates()
        return candidates.components
    end

    return {
        add_macro_candidate      = add_macro_candidate,
        get_macro_candidates     = get_macro_candidates,
        add_component_candidate  = add_component_candidate,
        get_component_candidates = get_component_candidates
    }
end}