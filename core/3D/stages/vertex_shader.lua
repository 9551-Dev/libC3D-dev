local matmul = require("core.3D.math.matmul")

return function(object,prev,geo,prop,efx,out,BUS,object_texture,camera)
    local transformed_vertices = {}
    local per = BUS.perspective.matrix

    local scale = prop.scale_mat
    local rot   = prop.rotation_mat
    local pos   = prop.pos_mat

    local shader = efx.vs

    local vertice_index = 0
    for i=1,#prev,3 do
        vertice_index = vertice_index + 1

        local new_vertice = {
            prev[i],prev[i+1],prev[i+2],1,index=vertice_index
        }

        local final_vertice

        if shader then
            final_vertice = shader(new_vertice,prop,scale,rot,pos,camera,per)
        else
            local scaled_vertice     = matmul(new_vertice,scale)
            local rotated_vertice    = matmul(scaled_vertice,rot)
            local translated_vertice = matmul(rotated_vertice,pos)
            local camera_transform
            if camera.transform then
                camera_transform = matmul(translated_vertice,camera.transform)
            else
                camera_transform = matmul(matmul(translated_vertice,camera.position),camera.rotation)
            end

            final_vertice = matmul(camera_transform,per)
        end

        transformed_vertices[vertice_index] = final_vertice
    end

    return transformed_vertices
end