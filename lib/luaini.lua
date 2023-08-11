local ini = {}

local function trim(s)
    return s:match("^()%s*$") and "" or s:match("^%s*(.*%S)")
end

local function parse_value(value)
    if value == "true" then
        return true
    elseif value == "false" then
        return false
    elseif tonumber(value) then
        return tonumber(value)
    elseif value:match("^%[.*%]$") then
        local tbl = {}
        local inner_data = value:sub(2, -2)
        for inner_line in inner_data:gmatch("[^\r\n]+") do
            local key, inner_value = inner_line:match("([^=]+)%s*=%s*(.+)")
            if key and inner_value then
                tbl[key] = parse_value(inner_value)
            end
        end
        return tbl
    else
        return value
    end
end

function ini.decode(data)
    local result = {}
    local current_group = result

    for line in data:gmatch("[^\r\n]+") do
        local section = line:match("%[([^%]]+)%]")
        if section then
            local subgroup_path = {}
            for subgroup_name in section:gmatch("[^.]+") do
                table.insert(subgroup_path, subgroup_name)
            end

            current_group = result
            for _, subgroup_name in ipairs(subgroup_path) do
                current_group[subgroup_name] = current_group[subgroup_name] or {}
                current_group = current_group[subgroup_name]
            end
        else
            local key, value = line:match("([^=]+)%s*=%s*(.+)")
            if key and value then
                key = trim(key)
                value = trim(value)

                current_group[key] = parse_value(value)
            end
        end
    end

    return result
end

local function encode_value(value)
    if type(value) == "table" then
        local items = {}
        for _, item in ipairs(value) do
            table.insert(items, tostring(item))
        end
        return "[" .. table.concat(items,", ") .. "]"
    else
        return tostring(value)
    end
end

local function encode_section(section_data, parent_path, indent)
    local lines = {}

    local found_value = false
    for key, value in pairs(section_data) do
        if type(value) ~= "table" then
            found_value = true
            lines[#lines + 1] = ("%s%s = %s"):format(("  "):rep(indent),key,encode_value(value))
        end
    end

    if found_value then
        lines[#lines + 1] = ""
    end

    for key, value in pairs(section_data) do
        if type(value) == "table" then
            local full_key = parent_path and (parent_path .. "." .. key) or key
            lines[#lines + 1] = ("%s[%s]"):format(("  "):rep(indent), full_key)
            lines[#lines + 1] = encode_section(value, full_key, indent + 1)
        end
    end

    return table.concat(lines, "\n")
end

function ini.encode(data)
    local ini_lines = {}

    local found_values_root = false

    for section_name, section_data in pairs(data) do
        if type(section_data) ~= "table" then
            found_values_root = true

            ini_lines[#ini_lines + 1] = ("%s = %s"):format(section_name,encode_value(section_data))
        end
    end

    if found_values_root then
        ini_lines[#ini_lines + 1] = ""
    end

    for section_name, section_data in pairs(data) do
        if type(section_data) == "table" then
            local full_section = ("[%s]"):format(section_name)
            ini_lines[#ini_lines + 1] = full_section
            ini_lines[#ini_lines + 1] = encode_section(section_data, section_name, 1)

        end
    end

    return table.concat(ini_lines, "\n")
end

return ini