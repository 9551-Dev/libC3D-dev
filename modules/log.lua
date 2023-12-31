return function(BUS)

    return function()
        local log = plugin.new("c3d:module->log")

        function log.register_modules()
            local module_registry = c3d.registry.get_module_registry()
            local log_module      = module_registry:new_entry("log")

            local log_api = BUS.log

            local log_types = getmetatable(BUS.log).__index

            log_module:set_entry(c3d.registry.entry("type"),log_types)

            log_module:set_entry(c3d.registry.entry("get_log"),function()
                return log_api
            end)

            log_module:set_entry(c3d.registry.entry("set_flatten"),function(state)
                log_api.disable_flatten = not state
            end)

            log_module:set_entry(c3d.registry.entry("add"),function(text,type)
                log_api(text,type)
            end)

            log_module:set_entry(c3d.registry.entry("dump"),function()
                log_api:dump()
            end)

            log_module:set_entry(c3d.registry.entry("bus_state"),function()
                local seen = {[BUS.log]=true,[BUS.c3d]=true,[BUS.ENV]=true,[BUS.graphics.buffer]=true,[BUS.mem]=true}
                local function printout(dist,val)
                    for k,v in pairs(val) do
                        if type(v) == "table" and not seen[v] then
                            log_api((" "):rep(dist).."|"..tostring(k)..("("..tostring(v)..")"),log_api.debug)
                            seen[v] = true
                            printout(dist+1,v)
                        else
                            log_api((" "):rep(dist).."|"..tostring(k).." -> "..tostring(v),log_api.debug)
                        end
                    end
                    if next(val) then log_api("",log_api.debug) end
                end
                printout(1,BUS)
                log_api("",log_api.info)
            end)

            log_module:set_entry(c3d.registry.entry("table"),function(t,typ)
                local seen = {}
                local function printout(dist,val)
                    for k,v in pairs(val) do
                        if type(v) == "table" and not seen[v] then
                            log_api((" "):rep(dist).."|"..tostring(k)..("("..tostring(v)..")"),typ or log_api.info)
                            seen[v] = true
                            printout(dist+1,v)
                        else
                            log_api((" "):rep(dist).."|"..tostring(k).." -> "..tostring(v),typ or log_api.info)
                        end
                    end
                    if next(val) then log_api("",typ or log_api.debug) end
                end
                printout(1,t)
                log_api("",typ)
            end)
        end

        log:register()
    end
end