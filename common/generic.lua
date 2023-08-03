---@diagnostic disable: need-check-nil
local generic = {}
function generic.uuid4()
    local random = math.random
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        return string.format('%x', c == 'x' and random(0, 0xf) or random(8, 0xb))
    end)
end

function generic.macro_id()
    local random = math.random
    local template ='xxyyyxx'
    return string.gsub(template, '[xy]', function (c)
        return string.format('%x', c == 'x' and random(0, 0xf) or random(8, 0xb))
    end)
end

function generic.precise_sleep(t)
    local ftime = os.epoch("utc")+t*1000
    while os.epoch("utc") < ftime do
        os.queueEvent("waiting")
        os.pullEvent("waiting")
    end

    os.queueEvent("waiting")
    os.pullEvent("waiting")
end

function generic.piece_string(str)
    local out = {}
    local n = 0
    str:gsub(".",function(c)
        n = n + 1
        out[n] = c
    end)
    return out
end

function generic.make_package_file_reader(lib_package)
    return {get_data_path=function(path)
        local identifier = ("__c3d_file_%s"):format(path)
        if lib_package.loaded[identifier] or lib_package.preload[identifier] then
            return lib_package.loaded[identifier] or lib_package.preload[identifier]
        else
            local found_file,err = lib_package.searchpath(path,lib_package.path)

            if not err then
                local file_handle = fs.open(found_file,"r")

                local data = file_handle.readAll()

                lib_package.loaded[identifier] = data

                file_handle.close()
                return data,found_file
            else
                error(err,2)
            end
        end
    end}
end

generic.events_with_cords = {
    monitor_touch=true,
    mouse_click=true,
    mouse_drag=true,
    mouse_scroll=true,
    mouse_up=true,
    mouse_move=true
}

return generic