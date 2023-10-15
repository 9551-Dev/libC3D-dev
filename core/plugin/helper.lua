local str   = require("common.string_util")
local parse = require("common.parser_util")

local tampl = require("lib.tampl")

return {
    set_registry_entry = function(register,registry_entry,value)
        if register.__rest.entry_lookup[registry_entry.name] and not registry_entry.forceful_override then
            error(str.interpolate("Tried to override existing registry entry $<group> -> $<name>, use the \"override\" entry flag"){
                group = register.__rest.name,
                name  = registry_entry.name
            },3)
        elseif registry_entry.forceful_override then
            local existing_entry = register.__rest.entry_lookup[registry_entry.name]

            register.__rest.entries     [existing_entry.id] = nil
            register.__rest.name_lookup [existing_entry.id] = nil
        end

        register.__rest.entries     [registry_entry.id]   = value
        register.__rest.entry_lookup[registry_entry.name] = registry_entry
        register.__rest.name_lookup [registry_entry.id]   = registry_entry.name
    end,

    bind = function(register,pointer)
        register.bound_to = pointer
        return register
    end,

    patch_plugin_file = function(source,f_prefix)
        local tokens = tampl.tokenize_source(source)

        local discovered_names    = {}
        local out_definition_args = {}

        local token_index = 1
        while token_index <= #tokens do
            local token = tokens[token_index].get and tokens[token_index]:get() or tokens[token_index]
            if token:match(str.interpolate("^$<1>"){str.depattern(f_prefix)}) and tokens[token_index+1] == "(" then
                discovered_names[#discovered_names+1] = token

                local call_start,call_end = parse.block(tokens,token_index,"(",")")

                local call_tokens = {}
                for _=call_start,call_end do
                    call_tokens[#call_tokens+1] = table.remove(tokens,call_start)
                end

                local call_data = tampl.generate_from_tokens(call_tokens,true)

                local call_arg_str,_,definition_args   = parse.stringify_call_arg1(call_data)
                out_definition_args[#discovered_names] = definition_args

                local processed = tampl.tokenize_source(call_arg_str)

                for current_token=#processed,1,-1 do
                    table.insert(tokens,call_start,processed[current_token])
                    token_index = token_index + 1
                end
            else
                token_index = token_index + 1
            end
        end

        return tampl.generate_from_tokens(tokens),discovered_names,out_definition_args
    end,
    quick_macro = function(BUS,this,list)
        local macro_data = {}

        local internal_data = {
            BUS            = BUS,
            macro_data     = this.macros,
            component_data = this.components,
            all            = this,
            parent         = this.parent,
            shr            = this.shared
        }

        for registry_id,macro_provider in pairs(list) do
            macro_data[macro_provider.entry_point] = {
                processor = function(utils,...)
                    utils.data = internal_data

                    local base_env = getfenv(macro_provider.data.processor)
                    local new_env  = setmetatable(this.inject or {},{__index=base_env})

                    setfenv(macro_provider.data.processor,new_env)

                    local result = table.pack(macro_provider.data.processor(utils,...))

                    setfenv(macro_provider.data.processor,base_env)

                    return table.unpack(result,1,result.n)
                end
            }
        end

        return macro_data
    end,
    quick_components = function(BUS,requester)
        local components_registered = {}

        local data_instance = requester.current_instance
        local instance_data = requester.instance_data[data_instance]

        local argument_label = requester.arguments

        for k,v in pairs(requester.components) do
            local component_entry = BUS.registry.component_registry:get(v.data.entry.id)

            components_registered[v.entry_point] = {
                processor=function(util,...)
                    local args = table.pack(...)

                    for i=1,args.n do
                        instance_data.arguments[i] = args[i].data
                    end
                    instance_data.arguments.n = args.n

                    return util.compile(component_entry:apply_self(requester))
                end
            }
        end

        return components_registered
    end
}