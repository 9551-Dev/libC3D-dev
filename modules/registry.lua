local registry = {}

local memory_manager = require("core.mem_manager")

return function(BUS)

    local memory_handle = memory_manager.get(BUS)

    local memory_bus = BUS.memory

    local default_binding = {}
    local binding = default_binding

    function registry.get_table(category)
        if not memory_bus[category] then memory_handle.init_category(category) end
        return memory_handle.get_table(category or 4)
    end

    function registry.get_module_registry(set_binding)
        return BUS.registry.module_registry:bind(set_binding or binding)
    end
    function registry.get_object_registry(set_binding)
        return BUS.registry.object_registry:bind(set_binding or binding)
    end
    function registry.get_thread_registry(set_binding)
        return BUS.registry.thread_registry:bind(set_binding or binding)
    end
    function registry.get_component_registry(set_binding)
        return BUS.registry.component_registry:bind(set_binding or binding)
    end
    function registry.get_macro_registry(set_binding)
        return BUS.registry.macro_registry:bind(set_binding or binding)
    end

    function registry.entry(name,value)
        return BUS.object.registry_entry.new(name,value)
    end

    function registry.bind(plugin)
        binding = plugin
    end
    function registry.unbind()
        binding = default_binding
    end

    return registry
end