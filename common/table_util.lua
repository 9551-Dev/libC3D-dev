local tbls = {}

function tbls.get_table_len(tbl)
    local realLen = 0
    for k,v in pairs(tbl) do
        realLen = realLen + 1
    end
    return realLen,#tbl
end

local function keys(tbl)
    local keys = {}
    for k,_ in pairs(tbl) do
        table.insert(keys,k)
    end
    return keys
end

function tbls.iterate_order(tbl,reversed)
    local indice = 0
    local keys = keys(tbl)
    table.sort(keys, function(a, b)
        if reversed then return b<a
        else return a<b end
    end)
    return function()
        indice = indice + 1
        if keys[indice] and tbl[keys[indice]] then return keys[indice],tbl[keys[indice]]
        else return end
    end
end

function tbls.merge_tables(...)
    local out = {}
    local n = 0
    for k,v in pairs({...}) do
        for _k,_v in pairs(v) do
            n = n + 1
            out[n] = _v
        end
    end
    return out
end

function tbls.createNDarray(n, tbl)
    tbl = tbl or {}
    if n == 0 then return tbl end
    setmetatable(tbl, {__index = function(t, k)
        local new = tbls.createNDarray(n - 1)
        t[k] = new
        return new
    end})
    return tbl
end

function tbls.deepcopy(tbl,keep,seen)
    local instance_seen = seen or {}
    local out = {}
    instance_seen[tbl] = out
    for copied_key,copied_value in pairs(tbl) do
        local is_table = type(copied_value) == "table" and not keep[copied_key]

        if type(copied_key) == "table" then
            if instance_seen[copied_key] then
                copied_key = instance_seen[copied_key]
            else
                local new_instance = tbls.deepcopy(copied_key,keep,instance_seen)
                instance_seen[copied_key] = new_instance
                copied_key = new_instance
            end
        end

        if is_table and not instance_seen[copied_value] then
            local new_instance = tbls.deepcopy(copied_value,keep,instance_seen)
            instance_seen[copied_value] = new_instance
            out[copied_key] = new_instance
        elseif is_table and instance_seen[copied_value] then
            out[copied_key] = instance_seen[copied_value]
        else
            out[copied_key] = copied_value
        end
    end

    return setmetatable(out,getmetatable(tbl))
end

function tbls.copy(tbl)
    local new = {}
    for k,v in pairs(tbl) do
        new[k] = v
    end
    return new
end

function tbls.map_iterator(w,h)
    return coroutine.wrap(function()
        for y=1,h do
            for x=1,w do
                coroutine.yield(x,y)
            end
        end
    end)
end

function tbls.reverse_table(tbl)
    local sol = {}
    for k,v in pairs(tbl) do
        sol[#tbl-k+1] = v
    end
    return sol
end

function tbls.create_blit_array(count)
    local out = {}
    for i=1,count do
        out[i] = {"","",""}
    end
    return out
end

return tbls
