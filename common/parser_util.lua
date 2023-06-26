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
    local param_name,name_mapping = input:match("(.+)[%[% ](.+)]")

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

return parse