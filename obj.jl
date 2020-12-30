#!/usr/local/bin/julia

#using ArgParse

const SCALE = 1
const SUB_DIVISIONS = 4
const PHI = Float64((1 + sqrt(5)) / 2)   # golden ratio
const PATH_OBJ_FILE = "./dev1.obj"


mutable struct DisplayedObject
    name
    origin
    scale
    verts
    normals
    faces
end


ObjectList = []

function vertex(x::Float64, y::Float64, z::Float64)

    len = sqrt(x^2 + y^2 + z^2)
    return [(i * SCALE) / len for i in (x,y,z)]
end

#=
const VERTS = [ 
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
=#

const VERTS = [ 
    [-1.0, PHI, 0.0], 
    [ 1.0, PHI, 0.0],
    [-1.0, -PHI, 0.0], 
    [ 1.0, -PHI, 0.0], 
    [0.0, -1.0, PHI], 
    [0.0, 1.0, PHI], 
    [0.0, -1.0, -PHI], 
    [0.0, 1.0, -PHI], 
    [ PHI, 0.0, -1.0], 
    [ PHI, 0.0, 1.0], 
    [-PHI, 0.0, -1.0], 
    [-PHI, 0.0, 1.0]
]


const FACES = [
    # 5 faces around point 1
    [1, 12, 6], [1, 6, 2], [1, 2, 8], [1, 8, 11], [1, 11, 12],
    # Adjacent faces
    [2, 6, 10], [6, 12, 5], [12, 11, 3], [11, 8, 7], [8, 2, 9], 
    # 5 faces around 4
    [4, 10, 5], [4, 5, 3], [4, 3, 7], [4, 7, 9], [4, 9, 10],
    # Adjacent faces
    [5, 10, 6], [3, 5, 12], [7, 3, 11], [9, 7, 8], [10, 9, 2], 
]

for vert in VERTS
    println(vert)
    x = vertex(vert[1], vert[2], vert[3])
    println(x)
end

#
# Main
#
println(PROGRAM_FILE); 
for x in ARGS 
    println(x); 
    end


Sphere1 = DisplayedObject("sphere1", [0.0, 0.0, 0.0], 1.0, [], [], [])
push!(ObjectList, Sphere1)
#Sphere2 = DisplayedObject("sphere2", [1.0, 0.0, 0.0], 1.0, [], [], [])
#push!(ObjectList, Sphere2)


function middle_point(object, point1, point2)

    # We check if we have already cut this edge first 
    # to avoid duplicated verts 
    smaller_index = min(point1, point2) 
    greater_index = max(point1, point2)

    key = "$smaller_index - $greater_index"
    if key in keys(Middle_point_cache)
        return Middle_point_cache[key]
    end

    # If it's not in cache, then we can cut it 
    vert1 = object.verts[point1] 
    vert2 = object.verts[point2] 
    middle = [sum(i)/2 for i in zip(vert1, vert2)]

    push!(object.verts, vertex(middle[1], middle[2], middle[3]))

    len_verts = length(object.verts)
    Middle_point_cache[key] = len_verts

    return len_verts

end


function compute_geometry(object)
    global FaceNormals = Dict()

    # initialize to base shape
    object.faces = FACES 
    #object.verts = broadcast(vertex(tmp, [vert + object.origin for vert in VERTS])
    tmp = [vert + object.origin for vert in VERTS]
    object.verts = [vertex(vert[1], vert[2], vert[3]) for vert in tmp]

    # sub-divide from there
    for i in 1:SUB_DIVISIONS
        faces_subdiv = [] 
        for tri in object.faces 
            #println(tri[1], tri[2])
            v1 = middle_point(object, tri[1], tri[2]) 
            v2 = middle_point(object, tri[2], tri[3]) 
            v3 = middle_point(object, tri[3], tri[1]) 
            push!(faces_subdiv,([tri[1], v1, v3])) 
            push!(faces_subdiv,([tri[2], v2, v1]))
            push!(faces_subdiv,([tri[3], v3, v2]))
            push!(faces_subdiv,([v1, v2, v3])) 
        end
        object.faces = faces_subdiv
    end

    for face in object.faces
        #println(face)
        vert_index = face[1]

        vert = object.verts[vert_index]
        x = vert[1]
        y = vert[2]
        z = vert[3]

        x_gradient = 2 * x
        y_gradient = 2 * y
        z_gradient = 2 * z
        gradient_vector = [x_gradient, y_gradient, z_gradient]
        magnitude = sqrt(x_gradient^2 + y_gradient^2 +  z_gradient^2)
        unit_vector = gradient_vector / magnitude

        push!(object.normals, unit_vector)
        FaceNormals[face] = length(object.normals)
    end

end


for object in ObjectList
    global Middle_point_cache

    Middle_point_cache = Dict()
    compute_geometry(object)

end

#
# write the file
#
open(PATH_OBJ_FILE, "w+") do f

    write(f, "#\n#\n")
    write(f, "# Julia 3DObject File Test\n")
    write(f, "#\n#\n")
    write(f, "o atomtest\n")

    for object in ObjectList
        count = 1
        for verts in object.verts
            x = round(verts[1], digits=6)
            y = round(verts[2], digits=6)
            z = round(verts[3], digits=6)
            write(f, "v $x $y $z\n")
            count += 1
        end

        for normal in object.normals
            x = round(normal[1], digits=6)
            y = round(normal[2], digits=6)
            z = round(normal[3], digits=6)
            write(f,"vn $x $y $z\n")
        end

        count = 1
        for face in object.faces
            normal_index = FaceNormals[face]
            x = face[1]
            y = face[2]
            z = face[3]
            #write(f, "f $x $y $z\n")
            write(f, "f $x $y $z #$count\n")
            write(f,"f $x//$normal_index $y//$normal_index $z//$normal_index\n")
            count += 1
        end

        count_faces = length(object.faces)
        count_vertices = length(object.verts)
        println("face count: $count_faces  vertex count: $count_vertices")
    end
end



println("DONE")
