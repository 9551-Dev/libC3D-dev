local clip_1 = require("core.3D.clipping.clip_1_vertex")
local clip_2 = require("core.3D.clipping.clip_2_vertices")

return function(object,tri_list,a,b,c,n,ps)
    local v1x,v1y,v1z,v1w = a[1],a[2],a[3],a[4]
    local v2x,v2y,v2z,v2w = b[1],b[2],b[3],b[4]
    local v3x,v3y,v3z,v3w = c[1],c[2],c[3],c[4]

    if v1x >  v1w and v2x >  v2w and v3x >  v3w then return n end
    if v1x < -v1w and v2x < -v2w and v3x < -v3w then return n end
    if v1y >  v1w and v2y >  v2w and v3y >  v3w then return n end
    if v1y < -v1w and v2y < -v2w and v3y < -v3w then return n end
    if v1z >  v1w and v2z > -v2w and v3z >  v3w then return n end
    if v1z < 0    and v2z < 0    and v3z < 0    then return n end

    if v1z < 0 then
        if v2z < 0 then
            n = n + 1
            clip_2(object,n,tri_list,a,b,c,ps)
        elseif v3z < 0 then
            n = n + 1
            clip_2(object,n,tri_list,a,c,b,ps)
        else
            n = n + 2
            clip_1(object,n,tri_list,a,b,c,ps)
        end
    elseif v2z < 0 then
        if v3z < 0 then
            n = n + 1
            clip_2(object,n,tri_list,b,c,a,ps)
        else
            n = n + 2
            clip_1(object,n,tri_list,b,a,c,ps)
        end
    elseif v3z < 0 then
        n = n + 2
        clip_1(object,n,tri_list,c,a,b,ps)
    else
        n = n + 1
        tri_list[n] = {a,b,c,ps=ps,object=object}
    end
    return n
end