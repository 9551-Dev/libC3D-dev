local parse   = require("common.parser_util")
local strutil = require("common.string_util")
local generic = require("common.generic")

local object = require("core.object")

local tampl = require("lib.tampl")

return function(BUS)
    local null_injection = tampl.compile_code("NULL")

    local macro_util_object = {
        __index=object.new({
            tampl   = tampl,
            compile = tampl.compile_code,
            make_varname = function(self,name)
                return strutil.interpolate("$<varname>_macro_$<macro_name>_$<macro_id>"){
                    varname    = name,
                    macro_name = self.name,
                    macro_id   = self.macro_id
                }
            end,
            wrap_doend = function(self,str)
                return strutil.interpolate("do\n$<code>\nend"){code=str}
            end,
            load_value = function(self,...)
                local values = table.pack(...)

                local return_values = {}

                for i=1,values.n do
                    local value = values[i]
                    if value then
                        local value_provider_source = ("return %s"):format(value)

                        local value_provider = load(value_provider_source,"=VALUE_PROVIDER","t",{})

                        if not value_provider then
                            error(("Error parsing value: %s"):format(tostring(value)),2)
                        end

                        if value_provider then
                            local ok,_return = pcall(value_provider)
                            if not ok then
                                error(("Error parsing value: %s"):format(tostring(value)),2)
                            else
                                return_values[i] = _return
                            end
                        end
                    end
                end

                return table.unpack(return_values,1,values.n)
            end,
            stitch = function(this,...)
                local data = {...}
                return table.concat(data,"\n")
            end,
            make_args = function(this,...)
                local vals = table.pack(...)

                local out = ""

                for i=1,vals.n do
                    local val = vals[i]
                    if val then
                        out = out .. val .. ","
                    end
                end

                return out:gsub(",$","")
            end,
            make_call = function(this,name,...)
                return (type(name) == "string" and name or "") .. ("(%s)"):format(this:make_args(...))
            end,
            read_internal = function(this,data_sources)
                local output = {}

                for i=1,data_sources.n do
                    output[i] = data_sources[i] and data_sources[i].data
                end

                return table.unpack(output,1,output.n)
            end,
            foreach = function(this,data,f)
                for i=1,data.n do
                    data[i] = f(data[i],i)
                end

                return data
            end,
            unwrap_string = function(this,str)
                if str then
                    return str:match("^.(.+).$")
                end
            end,
            wrap_string = function(this,str)
                if str then
                    return ("\"%s\""):format(str)
                end
            end
        },tampl),__tostring = function(self) return strutil.format_table__tostring(self) end,
        __type = "macro_util"
    }

    local function generate_macro_identity(name,index,for_processor)
        return (for_processor and "" or "_") .. ("c3d_macro_%s<%d>"):format(name,index)
    end

    local name_typings = {
        start  = {name=true},
        any    = {name=true,["."]=true,[":"]=true},
        fin    = {name=true},
        fbegin = {["("]=true}
    }

    local macro_levelization_rules = {
        {
            name   = "base",
            opener = {
                ["("] = true,
                ["{"] = true
            },
            closer = {
                [")"] = true,
                ["}"] = true
            }
        }
    }

    local function check_typing(parsed_token,partof)
        if partof.name and parsed_token.type == "name" then
            return true
        elseif parsed_token.type == "lua_token" and partof[parsed_token.name] then
            return true
        end

        return false
    end

    local ARGTYPES_ENUM = {
        ["func"]    = 1,
        ["generic"] = 2
    }

    local argument_types = {
        [ARGTYPES_ENUM.func] = {add=function(list,name,arguments,function_body)
            local f_def = ""
            for i=1,#arguments do
                f_def = f_def .. arguments[i] .. ","
            end

            f_def = f_def:gsub(",$","")

            local object = {
                name = name,
                args = arguments,
                body = function_body,
                data = ("function(%s) %s end"):format(f_def,tampl.generate_from_tokens(function_body))
            }

            local methodized = setmetatable(object,{__index={}})
            list[#list+1] = methodized

            return methodized
        end},
        [ARGTYPES_ENUM.generic] = {add=function(list,data)
            local object = {
                data = data
            }

            local methodized = setmetatable(object,{__index={}})
            list[#list+1] = methodized

            return methodized
        end}
    }

    local function process_macros(macro_source,macros,block_format)
        local name_start

        local tokens = tampl.tokenize_source(macro_source,true)

        local macro_injections = {}
        local macro_presence   = {}
        local check_functions  = {}
        for name,macro in pairs(macros) do
            macro_presence  [name] = 0
            macro_injections[name] = {
                name       = name,
                processor  = macro.processor,
                keep_hooks = macro.keep_hooks,
                macro_id   = generic.macro_id(),

                list = {}
            }

            if type(macro.check) == "function" then
                check_functions[#check_functions+1] = {check=macro.check,source=name}
            end
        end


        local token_index = 1
        while token_index <= #tokens do
            local current_token = tokens[token_index]
            local prev_token    = tokens[token_index-1]

            if check_typing(current_token:parse(),name_typings.start) and not name_start then
                name_start = token_index
            end

            if name_start and not check_typing(current_token:parse(),name_typings.any) then
                local is_function_begin = check_typing(current_token:parse(),name_typings.fbegin)
                local is_leading_name   = check_typing(prev_token   :parse(),name_typings.fin)

                if is_function_begin and is_leading_name then
                    local call_name  = ""
                    local call_block = {}

                    for slice_piece=name_start,token_index-1 do
                        call_name = call_name .. tokens[slice_piece]:get()
                    end

                    local check_function_result = false
                    local source_macro         = call_name
                    for i=1,#check_functions do
                        local resolver = check_functions[i]
                        local result   = resolver.check(call_name)

                        check_function_result = check_function_result or result

                        if result then
                            source_macro = resolver.source

                            break
                        end
                    end

                    if not tampl.data.keyword_lookup[call_name] and (macros[call_name] or check_function_result) then

                        local macro_instance_presence = macro_presence[source_macro] + 1

                        macro_presence[source_macro] = macro_instance_presence

                        local call_arguments = {}


                        local call_block_start,call_block_end = parse.block(tokens,token_index,"(",")")
                        for slice_piece=call_block_start,call_block_end  do
                            call_block[#call_block+1] = tokens[slice_piece]:get()
                        end

                        local tree           = tampl.tree_from_tokens     (call_block)
                        local parsed_tree    = parse.function_call_complex(tampl,tree)
                        local levelized_tree = parse.levelize(parsed_tree,macro_levelization_rules,function(token_data)
                            return token_data.scope_open and "" or tampl.tokenize_source(token_data[1])[1]
                        end,true)

                        local argument_stack = {}
                        for block_index=2,#parsed_tree-1 do
                            local element = parsed_tree[block_index]

                            if element.scope_source then
                                local function_arg = element[1]

                                local args = parse.function_args(function_arg)

                                local function_arg_tokens = tampl.label_tokens(tampl.tokenize_source(function_arg))

                                local argument_start,argument_end = parse.block(function_arg_tokens,1,"(",")",function(token)
                                    return (token.type == "lua_token") and token.name or ""
                                end)

                                local function_tokens = {}
                                for i=argument_end+1,#function_arg_tokens do
                                    function_tokens[#function_tokens+1] = function_arg_tokens[i]
                                end

                                argument_stack = {}
                                argument_types[ARGTYPES_ENUM.func].add(call_arguments,call_name,args,function_tokens)
                            else
                                local token = tampl.tokenize_source(element[1])[1]

                                local base_level = levelized_tree[block_index].level.base

                                if token == "," and base_level and base_level == 1 then
                                    local whole_arg = ""
                                    for i=1,#argument_stack do
                                        whole_arg = whole_arg .. table.remove(argument_stack,1)
                                    end
                                    argument_types[ARGTYPES_ENUM.generic].add(call_arguments,process_macros(whole_arg,macros,true))
                                elseif token ~= "end" then
                                    argument_stack[#argument_stack+1] = token
                                end
                            end
                        end

                        if next(argument_stack) then
                            local whole_arg = ""
                            for i=1,#argument_stack do
                                whole_arg = whole_arg .. table.remove(argument_stack,1)
                            end

                            argument_types[ARGTYPES_ENUM.generic].add(call_arguments,process_macros(whole_arg,macros,true))
                        end

                        macro_injections[source_macro].list[macro_instance_presence] = call_arguments

                        for i=name_start,call_block_end do
                            table.remove(tokens,name_start)
                        end

                        token_index = token_index - 1

                        local hook_identity = generate_macro_identity(source_macro,macro_instance_presence,true)
                        local hook_token    = tampl.build_raw_token(("--[[#%s]]"):format(hook_identity))

                        table.insert(tokens,name_start,hook_token)
                    end
                end

                name_start = nil
            end

            token_index = token_index + 1
        end

        local macro_patchable = tampl.new_patch_from_tokens(tokens)

        for macro_name,macro in pairs(macro_injections) do
            local dedicated_utils = setmetatable(macro,macro_util_object):__build()

            for macro_index=1,macro_presence[macro_name] do
                local arguments = macro.list[macro_index]

                local identity   = generate_macro_identity(macro_name,macro_index,false)
                local macro_hook = macro_patchable[identity]

                local injection_code = macro.processor(dedicated_utils,table.unpack(arguments))

                macro_patchable.inject(macro_hook,tampl.At("HEAD"),injection_code)
                if not macro.keep_hooks then
                    macro_patchable.inject(macro_hook,tampl.At("WIPE"),null_injection)
                end
            end
        end

        return macro_patchable.apply_patches(nil,block_format),macro_patchable
    end

    return {
        process=process_macros
    }
end