local parse = {}

local string_util = require("common.string_util")
local table_util  = require("common.table_util")

function parse.stack_trace(trace)
    trace = trace:gsub("stack traceback:","")
    local res = ""

    local noted_libc3d = false
    for c in trace:gmatch(".-\n") do
        if not c:match("libC3D/") then
            res = res .. c .. "\n"
        elseif not noted_libc3d then
            noted_libc3d = true
            res = res .. "(libC3D/..)"
        end
    end

    return res
end

function parse.layout_attributes(input,expected_names)
    local param_name,name_mapping = input:match("(.+)[%[% ](.-)]")

    local mapped_names = {}
    local n            = 1

    for s in (name_mapping or ""):gmatch("[^;]+") do
        mapped_names[n] = s
        n = n + 1
    end

    for i=1,expected_names do
        if not mapped_names[i] then mapped_names[i] = tostring(i) end
    end

    return param_name,mapped_names
end

function parse.function_args(call)
    local args_string = call:match("^%((.-)%)")

    local call_args = {}
    for c in args_string:gmatch("[^,]+") do
        call_args[#call_args+1] = c
    end
    return call_args
end

function parse.function_call(call)
    local name,args_string = call:match("^([%w_%.:]+)% ?%((.-)%)$")
    local call_args = {}

    if args_string then
        for c in args_string:gmatch("[^,]+") do
            call_args[#call_args+1] = c:gsub("^% *",""):gsub("% *$","")
        end
    end

    return name,call_args
end

function parse.iterate_filtered_calls(source,filter)
    return source:gmatch(filter .. "([%w_%.:]+)%((.-)%)")
end

function parse.function_call_complex(tampl,compiled_tree)
    local out_data = {}
    local TMP = {}
    for k,v in pairs(compiled_tree) do
        if v.entry == "token" then
            TMP[1] = v
            out_data[#out_data+1] = {
                tampl.new_patch_from_compiled(TMP).apply_patches(nil,true),
                scope_source = false
            }
        elseif v.entry == "scope" then
            out_data[#out_data+1] ={
                tampl.new_patch_from_compiled(v).apply_patches(nil,true),
                scope_source = true
            }
        end
    end

    return out_data
end

function parse.block(data,from,opener,closer,getter)
    local block_level  = 0

    local block_start = 1
    local block_end   = 1

    local found_first = false

    for i=from,#data do
        local val = data[i]
        if type(getter) == "function" then
            val = getter(val,i)
        end

        local char = val.get and val:get() or val.name or val

        if char == opener then
            block_level = block_level + 1

            if not found_first then
                block_start = i
            end

            found_first = true
        elseif char == closer then
            block_level = block_level - 1
        end

        if found_first and block_level == 0 then
            block_end = i
            break
        end
    end

    return block_start,block_end
end

function parse.levelize(token_source,level_types,getter,instantiate)
    local tokens = token_source
    if instantiate then
        tokens = table_util.deepcopy(token_source)
    end

    local level_track = {}

    for k,v in ipairs(level_types) do
        level_track[k] = 0
    end

    for token_id,token_provider in ipairs(tokens) do
        local token = token_provider
        if getter then
            token = getter(token_provider,token_id)
        end

        if not tokens[token_id].level then
            tokens[token_id] = {
                token = token,
                level = {}
            }
        end

        for k,level in ipairs(level_types) do
            local name    = level.name
            local opener  = level.opener
            local closer  = level.closer

            if type(opener) == "table" then
                opener = opener[token] and token
            end
            if type(closer) == "table" then
                closer = closer[token] and token
            end

            if token == opener then
                level_track[k] = level_track[k] + 1
            elseif token == closer then
                level_track[k] = level_track[k] - 1
            end

            tokens[token_id].level[name] = level_track[k]
        end
    end

    return tokens
end

function parse.head_arguments(data)
end

function parse.match_from_call(source)
    return source:match("()([%w_%.:]+()%(.-%).+)$")
end

function parse.stringify_call_arg1(str)
    local call_arg
    return str:gsub("^(%s-%(%s-)(function%s-%(.-%))",function(a,b)
        call_arg = b

        return a .. "[["
    end):gsub("(.*)end(.-)$",function(a,b)
        return a .. "]]" .. b
    end),str:match("^%s-%(%s-(function%s-%(.-%))"),select(2,parse.function_call(call_arg))
end

local function compare_with_wildcard(val1,val2)
    if val1 == "x" or val2 == "x" then
        return 0
    else
        return val1 - val2
    end
end

local function compare_versions(version1,version2)
    local major_cmp = compare_with_wildcard(version1.major,version2.major)
    local minor_cmp = compare_with_wildcard(version1.minor,version2.minor)

    if major_cmp ~= 0 then return major_cmp end
    if minor_cmp ~= 0 then return minor_cmp end

    return compare_with_wildcard(version1.patch,version2.patch)
end

function parse.is_version_within_range(version,range)
    local start_version = range.start_version
    local end_version   = range.end_version

    if range.is_range then
        local start_compatible = true
        local end_compatible   = true

        if start_version then
            start_compatible = compare_versions(version, start_version) >= 0
        end

        if end_version then
            end_compatible = compare_versions(version, end_version) <= 0
        end

        return start_compatible and end_compatible
    elseif start_version or end_version then
        local start_compatible = not start_version or compare_versions(version, start_version) >= 0
        local end_compatible   = not end_version   or compare_versions(version, end_version)   <= 0

        return start_compatible and end_compatible
    else
        return true
    end
end

function parse.single_version(version_part)
    local parts = string_util.split_on(version_part, ".")

    local major = ((parts[1] or "x"):lower() == "x" or parts[1] == "*") and "x" or tonumber(parts[1])
    local minor = ((parts[2] or "x"):lower() == "x" or parts[2] == "*") and "x" or tonumber(parts[2])
    local patch = ((parts[3] or "x"):lower() == "x" or parts[3] == "*") and "x" or tonumber(parts[3])

    return {
        major = major,
        minor = minor,
        patch = patch
    }
end

function parse.version(version_str)
    local version_parts = string_util.split_on(version_str, "-")

    if #version_parts == 1 then
        return parse.single_version(version_parts[1])
    elseif #version_parts == 2 then
        local range = {
            is_range = true,

            start_version = parse.single_version(version_parts[1]),
            end_version   = parse.single_version(version_parts[2])
        }

        return range
    end

    return nil
end

function parse.plugin_identifier(notation_str)
    local plugin_info = {}

    local registry,rest = notation_str:match("([^:]+):(.+)")
    if registry and rest then
        plugin_info.registry = registry
    else
        rest = notation_str
    end

    local category,plugin_part = rest:match("([^->]+)->(.+)")
    if category and plugin_part then
        plugin_info.category = category
    else
        plugin_part = rest
    end

    local plugin,version_str = plugin_part:match("([%w-_#]+)#([%d.x%*%-]+)")
    if plugin then
        plugin_info.plugin = plugin

        plugin_info.version = parse.version(version_str)
    elseif plugin_part ~= "" then
        plugin_info.plugin = plugin_part
    end

    return plugin_info.plugin and plugin_info
end

return parse