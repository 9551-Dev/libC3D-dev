local parse = {}

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

function parse.function_call(call)
    local name,args_string = call:match("^([%w_%.:]+)%((.-)%)$")
    local call_args = {}
    for c in args_string:gmatch("[^,]+") do
        call_args[#call_args+1] = c
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
            out_data[#out_data+1] = tampl.new_patch_from_compiled(TMP).apply_patches()
        elseif v.entry == "scope" then
            out_data[#out_data+1] = tampl.new_patch_from_compiled(v).apply_patches()
        end
    end

    return out_data
end

function parse.head_arguments(data)
    local bracket_level  = 0
    local arguments_end  = 1

    local found_first = false

    for i=1,#data do
        local char = data:sub(i,i)

        if char == "(" then
            bracket_level = bracket_level + 1
            found_first = true
        elseif char == ")" then
            bracket_level = bracket_level - 1
        end

        if found_first and bracket_level == 0 then
            arguments_end = i
            break
        end
    end

    return data:sub(arguments_end+1),data:sub(1,arguments_end)
end

return parse