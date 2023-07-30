local loaded_registries = {
    require("core.plugin.registries.component_registry"),
    require("core.plugin.registries.macro_registry"),
    require("core.plugin.registries.module_registry"),
    require("core.plugin.registries.object_registry"),
    require("core.plugin.registries.plugin_registry"),
    require("core.plugin.registries.thread_registry")
}

return {for_bus=function(BUS)
    local function attach_registries()
        for registry_index,registry in ipairs(loaded_registries) do
            local reference = registry.attach(BUS)

            reference.identifier = registry_index
        end
    end

    attach_registries()

    return {reattach=attach_registries}
end}