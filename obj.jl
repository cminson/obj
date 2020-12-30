#!/usr/local/bin/julia

#using ArgParse


#
# Main
#
println("OBJ")
println(PROGRAM_FILE); 
for x in ARGS 
    println(x); 
    end


const SCALE = 1
const SUB_DIVISIONS = 3
const NAME = "SPHERE"
const PHI = Float64((1 + sqrt(5)) / 2)   # golden ratio

PATH_OBJ_FILE = "./dev1.obj"

middle_point_cache = Dict()

function vertex(x::Float64, y::Float64, z::Float64)

    len = sqrt(x^2 + y^2 + z^2)
    return [(i * SCALE) / len for i in (x,y,z)]
end


function middle_point(point1, point2)

    # We check if we have already cut this edge first 
    # to avoid duplicated verts 
    smaller_index = min(point1, point2) 
    greater_index = max(point1, point2)

    key = "$smaller_index - $greater_index"
    if key in keys(middle_point_cache)
        return middle_point_cache[key]
    end

    # If it's not in cache, then we can cut it 
    vert1 = Verts[point1] 
    vert2 = Verts[point2] 
    middle = [sum(i)/2 for i in zip(vert1, vert2)]

    push!(Verts, vertex(middle[1], middle[2], middle[3]))

    len_verts = length(Verts)
    middle_point_cache[key] = len_verts

    return len_verts

end


Verts = [ 
    vertex(-1.0, PHI, 0.0), 
    vertex( 1.0, PHI, 0.0),
    vertex(-1.0, -PHI, 0.0), 
    vertex( 1.0, -PHI, 0.0), 
    vertex(0.0, -1.0, PHI), 
    vertex(0.0, 1.0, PHI), 
    vertex(0.0, -1.0, -PHI), 
    vertex(0.0, 1.0, -PHI), 
    vertex( PHI, 0.0, -1.0), 
    vertex( PHI, 0.0, 1.0), 
    vertex(-PHI, 0.0, -1.0), 
    vertex(-PHI, 0.0, 1.0)
]


Faces = [
    # 5 faces around point 1
    [1, 12, 6], [1, 6, 2], [1, 2, 8], [1, 8, 11], [1, 11, 12],
    # Adjacent faces
    [2, 6, 10], [6, 12, 5], [12, 11, 3], [11, 8, 7], [8, 2, 9], 
    # 5 faces around 4
    [4, 10, 5], [4, 5, 3], [4, 3, 7], [4, 7, 9], [4, 9, 10],
    # Adjacent faces
    [5, 10, 6], [3, 5, 12], [7, 3, 11], [9, 7, 8], [10, 9, 2], 
]


Normals = []
FaceNormals = Dict()
                                                   
                                                   

for i in 1:SUB_DIVISIONS
    global Faces

    faces_subdiv = [] 
    for tri in Faces 
        #println(tri[1], tri[2])
        v1 = middle_point(tri[1], tri[2]) 
        v2 = middle_point(tri[2], tri[3]) 
        v3 = middle_point(tri[3], tri[1]) 
        push!(faces_subdiv,([tri[1], v1, v3])) 
        push!(faces_subdiv,([tri[2], v2, v1]))
        push!(faces_subdiv,([tri[3], v3, v2]))
        push!(faces_subdiv,([v1, v2, v3])) 
    end
    Faces = faces_subdiv

end

#
# calculate normals
# 2x, 2y, 2z
# divided by magntiude
#
for face in Faces
    #println(face)
    vert_index1 = face[1]

    vert = Verts[vert_index1]
    x = vert[1]
    y = vert[2]
    z = vert[3]

    x_gradient = 2 * x
    y_gradient = 2 * y
    z_gradient = 2 * z
    gradient_vector = [x_gradient, y_gradient, z_gradient]
    magnitude = sqrt(x_gradient^2 + y_gradient^2 +  z_gradient^2)
    unit_vector = gradient_vector / magnitude
    #println(unit_vector)

    push!(Normals, unit_vector)
    FaceNormals[face] = length(Normals)

end



open(PATH_OBJ_FILE, "w+") do f

    write(f, "#\n#\n")
    write(f, "# Julia Object File Test\n")
    write(f, "#\n#\n")
    write(f, "o atomtest\n")

    count = 1
    for verts in Verts
        x = round(verts[1], digits=6)
        y = round(verts[2], digits=6)
        z = round(verts[3], digits=6)
        write(f, "v $x $y $z\n")
        count += 1
    end

    for normal in Normals
        x = round(normal[1], digits=6)
        y = round(normal[2], digits=6)
        z = round(normal[3], digits=6)
        write(f,"vn $x $y $z\n")
    end

    count = 1
    for face in Faces
        normal_index = FaceNormals[face]
        x = face[1]
        y = face[2]
        z = face[3]
        #write(f, "f $x $y $z\n")
        write(f, "f $x $y $z #$count\n")
        write(f,"f $x//$normal_index $y//$normal_index $z//$normal_index\n")
        count += 1
    end

end


count_faces = length(Faces)
count_vertices = length(Verts)
println("face count: $count_faces  vertex count: $count_vertices")

println("DONE")
