local code_formatter = require("lib.format_code")

local TEMPLATE_TYPE = {}

local function lookupify(tbl)
    local lookup = {}
    for k,v in pairs(tbl) do lookup[v] = k end
    return lookup
end

local function combined_lookup(a,b)
    local lookup = {}
    for k,v in pairs(b) do lookup[a[k]] = v end
    return lookup
end

local keywords = {
    "and",   "break", "do",  "else",    "elseif",
    "end",   "false", "for", "function","if",
    "in",    "local", "nil", "not",     "or",
    "repeat","return","then","true",    "until","while"
}

local lua_tokens = {
    "+", "-", "*", "/", "%", "^","#",
    "==","~=","<=",">=","<", ">","=",
    "(", ")", "{", "}", "[", "]",
    ";", ":", ",", ".", "..","..."
}

local keyword_value_proccessor = {
    value={
        ["true"] =function() return true  end,
        ["false"]=function() return false end,
        ["nil"]  =function() return nil   end
    },
}

local expansible_tokens = {
    ["="]   ="=",
    ["=="]  ="=",
    ["~"]   ="=",
    ["~="]  ="=",
    ["<"]   ="=",
    ["<="]  ="=",
    [">"]   ="=",
    [">="]  ="=",
    ["."]   =".",
    [".."]  =".",
    ["..."] ="",
    ["-"]   ="-",
    ["--"]  ="[",
    ["["]   ="[",
    ["[["]  ="[",
    ["]"]   ="]",
    ["]]"]  ="]",
    ["--["] ="[",
    ["--[["]="["
}

local scope = {
    open_begin = lookupify{
        "if","elseif","while","for"
    },
    open = lookupify{
        "do","else","then","function","repeat"
    },
    close = lookupify{
        "end","elseif","else","until"
    }
}

local positioning_types = {
    "HEAD","TAIL","THIS","WIPE"
}
local positioning_handles = {
    function(tree,position,type,simple_override)
        if not simple_override then
            local tree_size = #tree
            for i=tree_size,position,-1 do
                local val = tree[i]

                local hook = val.hook_info
                if hook then hook.index = hook.index + 1 end

                tree[i+1] = val
            end
        end

        tree[position] = type
    end,
    function(tree,position,type,simple_override,tail_handle)
        if not simple_override then
            local tree_size = #tree
            for i=tree_size,position,-1 do
                local val = tree[i]

                local hook = val.hook_info
                if hook then hook.index = hook.index + 1 end

                tree[i+1] = val
            end
        end

        tree[position+(tail_handle or 0)] = type
    end,
    function(tree,position,type)
        tree[position] = type
    end,
    function(tree,position)
        local tree_size = #tree
        tree[position] = nil
        for i=position+1,tree_size do
            local val = tree[i]

            local hook = val.hook_info
            if hook then hook.index = hook.index - 1 end

            tree[i-1] = val
        end
        tree[tree_size] = nil
    end
}

local positioning_offsets = {
    0,1,1,0
}

local hook_types = {
    "#","$","="
}
local hook_type_handles = {
    function(tree,position,type,positioning)
        positioning(tree,position,type)
    end,
    function(tree,position,type,positioning)
        positioning(tree,position-1,type,true)
    end,
    function(tree,position,type,positioning)
        positioning(tree,position-1,type,true,1)
    end
}

local hooks              = combined_lookup(hook_types,hook_type_handles)
local relative_positions = combined_lookup(positioning_types,positioning_handles)
local relative_offsets   = combined_lookup(positioning_types,positioning_offsets)

local keyword_lookup = lookupify(keywords)
local token_lookup   = lookupify(lua_tokens)

local function generate_tokens(str)
    str = str .. "\0"
    local tokens = {}
    local token = ""

    local is_string   = false
    local is_number   = false
    local is_comment  = false
    local is_mulline  = false
    local escape_next = false

    local can_expand = ""

    for i=1,#str-1 do
        local char      = str:sub(i,i)
        local next_char = str:sub(i+1,i+1)

        if (char == "\'" or char == "\"") and not is_comment then
            if not escape_next then is_string = not is_string end
        end
        if char == "\\" then
            escape_next = true
        end
        if char == "\n" and not is_mulline then is_string,is_comment,is_number = false,false,false end

        if not is_string and (char:match("%d") or (char == "." and next_char:match("%d"))) then
            is_number = true
        elseif char ~= "." then
            is_number = false
        end

        if char:match("[%s\t]") and not is_string and not is_comment and not is_number then
            if token ~= "" then tokens[#tokens+1] = token end
            token = ""
        elseif token_lookup[char] and not is_string and not is_number and not is_comment then
            if token ~= "" then tokens[#tokens+1] = token end
            
            if not expansible_tokens[char] then
                tokens[#tokens+1] = char
            end

            token = ""
        elseif not expansible_tokens[char] or is_string or is_number or is_comment then
            token = token .. char
            escape_next = false
        end

        if (((expansible_tokens[can_expand] == char) or (can_expand == "" and expansible_tokens[char]))) and not is_number then
            can_expand = can_expand .. char
            if not expansible_tokens[can_expand .. next_char] then
                if can_expand == "--" and not is_string and not is_number and not is_comment then
                    token = token .. "--"
                    is_comment = true
                elseif (can_expand == "[[" or can_expand == "--[[") and not is_string and not is_number and not is_comment then
                    token = token .. can_expand
                    if can_expand == "--[[" and not escape_next then
                        is_comment = true
                    elseif can_expand == "[[" and not escape_next then
                        is_string  = true
                    end
                    is_mulline = true
                elseif can_expand == "]]" and is_mulline and not escape_next then
                    tokens[#tokens+1] = token
                    token = ""
                    is_mulline,is_string,is_comment,is_number = false,false,false,false
                elseif not is_string and not is_number and not is_comment then
                    tokens[#tokens+1] = can_expand
                end
                can_expand = ""
            end
        end
    end

    if token ~= "" then tokens[#tokens+1] = token end

    return tokens
end

local function make_value(token,token_buffer,token_index)
    local out
    if keyword_lookup[token] then
        local keyword_type = keyword_lookup[token]
        if keyword_type and keyword_value_proccessor[keyword_type] then
            out = keyword_value_proccessor[keyword_type][token](token_buffer,token_index)
        end
    elseif token_lookup[token] then
        out = "lua_token"
    elseif token:match("^%-%-")    or token:match("^%-%-%[%[.+%]%]$") then
        out = token:match("^%-%-%[%[(.+)%]%]$") or token:match("^%-%-(.+)")
    elseif token:match("^\".+\"$") or token:match("^%[%[.+%]%]$") then
        out = token:match("^%[%[(.+)%]%]$") or token:match("^\"(.+)\"$")
    elseif token:match("(%d*%.?%d+)") then
        out = tonumber(token)
    else out = token end
    
    return out
end

local function make_type(token)
    local out
    local keyword_type
    if keyword_lookup[token] then
        out = "lua_keyword"
        keyword_type = keyword_lookup[token]
    elseif token_lookup[token] then
        out = "lua_token"
    elseif token:match("^%-%-")    or token:match("^%-%-%[%[.+%]%]$") then
        out = "comment"
    elseif token:match("^\".+\"$") or token:match("^%[%[.+%]%]$") then
        out = "string"
    elseif token:match("(%d*%.?%d+)") then
        out = "number"
    else out = "name" end

    return out,keyword_type
end

local TOKEN_MT = {__tostring=function(self) return "TOKEN: " .. self.type  end}
local SCOPE_MT = {__tostring=function(self) return "SCOPE: " .. self.index end}

local HOOK_MT = {__index={
    set_type = function(self,type)
        self.type = type
    end
},__tostring=function(self) return "HOOK: " .. self.name end}

local function parse_token(out,token,token_buffer,token_index)
    out.entry  = "token"
    out.name   = token

    out.type,out.keyword_type = make_type (token)
    out.value                 = make_value(token,token_buffer,token_index)

    setmetatable(out,TOKEN_MT)

    return out
end

local function generate_extra_hook_info(t)
    local hook = t.scope[t.index]
    hook.hook_info = t

    t.hook_comment = hook
    t.name = hook.value:match("^.(.+)")
    t.type = hook.value:match("^.")

    return setmetatable(t,HOOK_MT)
end

local function find_hooks(tree,lst)
    lst = lst or {}
    for k,v in ipairs(tree) do
        if v.entry == "scope" then
            find_hooks(v,lst)
        elseif v.type == "comment" then
            local new_index = #lst+1
            local new = generate_extra_hook_info{scope=tree,index=k,hook_index=new_index}
            if hooks[new.type] then
                lst[new_index] = new
            end
        end
    end

    return lst
end

local function generate_code_tree(tokens)
    local current_scope = {}

    local token_buffer = {}
    local buffer_open  = false

    local scope_index = 0

    for i=1,#tokens do
        local current_token = tokens[i]

        if scope.open_begin[current_token] then
            buffer_open = true
        end
        if buffer_open then
            token_buffer[#token_buffer+1] = current_token
        end

        if scope.close[current_token] then
            current_scope = current_scope.parent
        end

        current_scope[#current_scope+1] = parse_token({},current_token,nil,i)
        
        if scope.open[current_token] then

            scope_index = scope_index + 1

            local new_scope = setmetatable({
                index = scope_index,
                parent  = current_scope,
                keyword = current_token,
                entry   = "scope"
            },SCOPE_MT)

            token_buffer = {}
            buffer_open = false

            current_scope[#current_scope+1] = new_scope

            current_scope = new_scope
        end
    end

    return current_scope
end

local function format_code_block(code)
    return code_formatter.format(code)
end

local function load_template_tree(tree)
    local template_hooks = find_hooks(tree)

    local object;object = {
        inject=function(hook_list,position,code)
            local code_tree      = code
            local rebuild_on_end = false

            if type(hook_list) ~= "table" then
                error("Invalid hook",2)
            end
            if type(code_tree) == "table" and code_tree.type == TEMPLATE_TYPE then
                code_tree      = code.tree
                rebuild_on_end = true
            end

            for k,hook in ipairs(hook_list) do
                local scope = hook.scope
                for k,v in ipairs(code_tree) do
                    hooks[hook.type](scope,hook.index+k*position.offset,v,position.pos)
                end
            end

            if rebuild_on_end then object.rebuild() end
            return object
        end,
        apply_patches=function(input)
            local code = ""

            for k,v in ipairs(input or tree) do
                if v.entry == "scope" then
                    code = code .. object.apply_patches(v) .. "\n"
                else
                    code = code .. v.name .. (v.type == "comment" and "\n" or " ")
                end
            end

            return format_code_block(code)
        end,
        rebuild = function()
            local reconstructed = load_template_tree(tree)

            for k,v in pairs(reconstructed) do
                object[k] = v
            end

            return reconstructed
        end,
        tree = tree,
        type = TEMPLATE_TYPE
    }

    for k,v in pairs(template_hooks) do
        local index_name = ("_%s"):format(v.name)

        if not object[index_name] then object[index_name] = {} end
        local hook_named = object[index_name]
        
        hook_named[#hook_named+1] = v
    end

    return object
end

local function load_template_tokens(tokens)
    return load_template_tree(generate_code_tree(tokens))
end

local function load_template(data)
    return load_template_tokens(generate_tokens(data))
end


local function load_template_file(path)
    local file = fs.open(path,"r")
    local data = file.readAll()

    file.close()

    return load_template_tokens(generate_tokens(data))
end

local function parse_code_block(data)
    local tokens = generate_tokens   (data)
    local tree   = generate_code_tree(tokens)

    return tree
end

local function inject_table_position(tp)
    return {pos=relative_positions[tp],offset=relative_offsets[tp]}
end

return {
    new_patch      = load_template,
    from_file      = load_template_file,
    from_tokens    = load_template_tokens,
    from_tree      = load_template_tree,
    compile_code   = parse_code_block,
    At             = inject_table_position,
    format_code    = format_code_block
}