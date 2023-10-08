local strings = {}

function strings.wrap(str,lenght,nnl)
    local words,out,outstr = {},{},""
    for c in str:gmatch("[%w%p%a%d]+%s?") do table.insert(words,c) end
    if lenght == 0 then return "" end
    while outstr < str and not (#words == 0) do
        local line = ""
        while words ~= 0 do
            local word = words[1]
            if not word then break end
            if #word > lenght then
                local espaces = word:match("% +$") or ""
                if not ((#word-#espaces) <= lenght) then
                    local cur,rest = word:sub(1,lenght),word:sub(lenght+1)
                    if #(line..cur) > lenght then words[1] = strings.wrap(cur..rest,lenght,true) break end
                    line,words[1],word = line..cur,rest,rest
                else word = word:sub(1,#word-(#word - lenght)) end
            end
            if #(line .. word) <= lenght then
                line = line .. word
                table.remove(words,1)
            else break end
        end
        table.insert(out,line)
    end
    return table.concat(out,nnl and "" or "\n")
end

function strings.cut_parts(str,part_size)
    local parts = {}
    for i = 1, #str, part_size do
        parts[#parts+1] = str:sub(i, i+part_size-1)
    end
    return parts
end

function strings.ensure_size(str,width)
    local f_line = str:sub(1, width)
    if #f_line < width then
        f_line = f_line .. (" "):rep(width-#f_line)
    end
    return f_line
end

function strings.newline(tbl)
    return table.concat(tbl,"\n")
end

function strings.wrap_lines(str,lenght)
    local result_str = ""
    for c in str:gmatch("([^\n]+)") do
        result_str = result_str .. strings.wrap(c,lenght) .. "\n"
    end
    return result_str
end

function strings.ensure_line_size(str,width)
    local result_str = ""
    for c in str:gmatch("([^\n]+)") do
        result_str = result_str .. strings.ensure_size(c,width) .. "\n"
    end
    return result_str
end

function strings.function_usage(f)
    local fArgs = ""
    if type(f) == "function" then
        local info = debug.getinfo(f, "u")
        local params = info.nparams
        if info.isvararg and params == 0 then
            fArgs = "(...)"
        else
            for i = 1, params do
                local param = debug.getlocal(f, i) or ""
                fArgs = fArgs .. param .. (i == params and "" or ", ")
            end
            if info.isvararg then
                fArgs = fArgs .. ", ..."
            end
            fArgs = "(" .. fArgs .. ")"
        end
    else
        fArgs = " " .. tostring(f)
    end
    return fArgs
end

function strings.format_table__tostring(tbl, visited, indent, key_stack, path_table, root_path)
    if not visited    then visited    = {} end
    if not indent     then indent     = 1  end
    if not key_stack  then key_stack  = {} end
    if not path_table then path_table = {} end
    if not root_path  then root_path  = "" end

    local current_path = table.concat(key_stack, ".")

    if visited[tbl] then
        local circular_key = table.concat(key_stack, ".")
        local reference_to = (visited[tbl] ~= "") and visited[tbl] or "__root__"
        return "<circular reference at: " .. circular_key .. ", points to: " .. reference_to .. ">"
    end

    local str = "{\n"
    visited[tbl] = current_path
    if not path_table[current_path] then
        path_table[current_path] = table.concat(key_stack, ".")
    end

    for k, v in pairs(tbl) do
        table.insert(key_stack, tostring(k))
        local key_str = (" "):rep(indent * 4) .. tostring(k) .. " = "

        if type(v) == "function" then
            v = "function" .. strings.function_usage(v)
        elseif type(v) == "table" then
            v = strings.format_table__tostring(v, visited, indent + 1, key_stack, path_table, root_path)
        elseif type(v) == "string" then
            local lines = {}

            local newline_cnt = 0

            for line in (v):gmatch("[^\r\n]+") do
                newline_cnt = newline_cnt + 1

                local padding = (newline_cnt > 1) and (" "):rep(indent * 4) or ""

                table.insert(lines,padding..line)
            end
            v = "\"" .. table.concat(lines,"\n") .. "\""
        else
            v = tostring(v)
        end
        table.remove(key_stack)

        str = str .. key_str .. v
        if next(tbl,k) then
            str = str .. ","
        end

        str = str .. "\n"
    end

    str = str .. (" "):rep((indent - 1) * 4) .. "}"

    if visited[tbl] then
        visited[tbl] = nil
    end

    return str
end

function strings.interpolate(str)
    return function(data)
        return str:gsub("%$<(.-)>",function(lookup_name)
            return data[tonumber(lookup_name) or lookup_name]
        end)
    end
end

function strings.depattern(str)
    return str:gsub("[%[%]%(%)%.%+%-%%%$%^%*%?]","%%%1")
end

function strings.replace(str,old,new)
    return str:gsub(str.depattern(old),str.depattern(new))
end

function strings.split_on(input_str,separator)
    local parts,start_idx = {},1

    while true do
        local found_idx = input_str:find(separator,start_idx,true)
        local part      = input_str:sub(start_idx,(found_idx or 0) - 1)

        if part ~= "" then parts[#parts+1] = part end

        if not found_idx then break end

        start_idx = found_idx + #separator
    end

    return parts
end

return strings