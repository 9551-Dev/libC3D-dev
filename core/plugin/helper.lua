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

        local discovered_names = {}

        local token_index = 1
        while token_index <= #tokens do
            local token = tokens[token_index]
            if token:match(str.interpolate("^$<1>"){str.depattern(f_prefix)}) and tokens[token_index+1] == "(" then
                discovered_names[#discovered_names+1] = token

                local call_start,call_end = parse.block(tokens,token_index,"(",")")

                local call_tokens = {}
                for _=call_start,call_end do
                    call_tokens[#call_tokens+1] = table.remove(tokens,call_start)
                end

                local call_data = tampl.generate_from_tokens(call_tokens,true)
                local processed = tampl.tokenize_source     (parse.stringify_call_arg1(call_data))

                for current_token=#processed,1,-1 do
                    table.insert(tokens,call_start,processed[current_token])
                    token_index = token_index + 1
                end
            else
                token_index = token_index + 1
            end
        end

        return tampl.generate_from_tokens(tokens),discovered_names
    end
}