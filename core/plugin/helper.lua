local str = require("common.string_util")

return {set_registry_entry=function(register,registry_entry,value)
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
end}