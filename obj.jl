#!/usr/local/bin/julia

#using ArgParse
using LinearAlgebra


#=
pm = picometer
1 angstrom = 100 picometer
O 152 pm
=#

const SCALE = 1
const SUB_DIVISIONS = 3
const PHI = Float64((1 + sqrt(5)) / 2)   # golden ratio
const PATH_OBJ_FILE = "./dev1.obj"
const HYDROGEN_DIAMETER = 25 #picometers

mutable struct Atom
    name
    origin
    verts
    normals
    uvs
    faces
end

struct AtomAttributes
    name
    scale
    material
end


DisplayedAtomsList = []
AtomAttributesDict = Dict([
    ("H", AtomAttributes("Hydrogen", 1.0, "shinyred"))
    ("O", AtomAttributes("Oxygen", 53 / HYDROGEN_DIAMETER, "shinyblue"))
    ])


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


function vertex(object::Atom, x::Float64, y::Float64, z::Float64)

    len = sqrt(x^2 + y^2 + z^2)
    scale = AtomAttributesDict[object.name].scale
    #println(scale)
    return [(i * scale) / len for i in (x,y,z)]
end

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

    push!(object.verts, vertex(object, middle[1], middle[2], middle[3]))

    len_verts = length(object.verts)
    Middle_point_cache[key] = len_verts

    return len_verts

end


function angle_vectors(v1, v2)

    magnitude1 = sqrt(v1[1]^2 + v1[2]^2 +  v1[3]^2)
    magnitude2 = sqrt(v2[1]^2 + v2[2]^2 +  v2[3]^2)
    magnitude = magnitude1 * magnitude2
    dot_product = dot(v1, v2)
    angle = rad2deg(acos(dot_product / (magnitude1 * magnitude2)))
    #println("angle $v1 $v2 $dot_product $magnitude")
    return floor(Int, angle)

end


function compute_geometry(object)
    global FaceNormals = Dict()

    # initialize to base shape
    object.faces = FACES 
    tmp = [vert for vert in VERTS]
    object.verts = [vertex(object, vert[1], vert[2], vert[3]) for vert in VERTS]
    #println(object.verts)

    # sub-divide faces into more triangles, up to count SUB_DIVISIONS
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

    # calculate normals for each face
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

    # calculate uv (texture) coords for each vertex
    for vert in object.verts
        u = vert[1]
        v = vert[2]
        push!(object.uvs, [u, v])
    end
end




#
# Main
#=
println(PROGRAM_FILE); 
for x in ARGS 
    println(x); 
    end
=#
push!(DisplayedAtomsList, Atom("O", [0.0, 0.0, 0.0], [], [], [], []))
#push!(DisplayedAtomsList, Atom("H", [3.0, 0.0, 0.0], [], [], [], []))
#push!(DisplayedAtomsList, Atom("H", [0.0, 3.0, 0.0], [], [], [], []))

for object in DisplayedAtomsList
    global Middle_point_cache

    Middle_point_cache = Dict()
    compute_geometry(object)
end


# output the obj file
println("Output:  $PATH_OBJ_FILE")
open(PATH_OBJ_FILE, "w+") do f

    total_objects = total_faces = total_normals = total_verts = total_uv = 0

    write(f, "# Julia 3DObject DEV \n")
    write(f, "mtllib master.mtl\n")

    for object in DisplayedAtomsList

        name = object.name
        material = AtomAttributesDict[object.name].material
        write(f, "o $name\n")
        first_vert = object.verts[1]
        for verts in object.verts
            x = round(verts[1], digits=6) + object.origin[1]
            y = round(verts[2], digits=6) + object.origin[2]
            z = round(verts[3], digits=6) + object.origin[3]
            write(f, "v $x $y $z\n")
            #angle = angle_vectors([4, -3, 5], [9, 7, -10])
            angle = angle_vectors(first_vert, verts)
            println("angle: $angle")
        end
        
        for uv in object.uvs
            u = round(uv[1], digits=6)
            v = round(uv[2], digits=6)
            write(f, "vt $u $v\n")
        end

        for normal in (object.normals)
            x = round(normal[1], digits=6)
            y = round(normal[2], digits=6)
            z = round(normal[3], digits=6)
            write(f,"vn $x $y $z\n")
        end

        write(f, "usemtl $material\n")
        for face in object.faces
            normal_index = FaceNormals[face] + total_normals
            x = face[1] + total_verts
            y = face[2] + total_verts
            z = face[3] + total_verts

            #write(f, "f $x $y $z\n")
            write(f,"f $x/$x/$normal_index $y/$y/$normal_index $z/$z/$normal_index\n")
            total_faces += 1
        end

        object_face_count = length(object.faces)
        object_vert_count = length(object.verts)
        object_normals_count = length(object.normals)
        object_name = object.name
        println("object: object_name  faces: $object_face_count  vertices $object_vert_count  normals: $object_normals_count ")

        total_normals += length(object.normals)
        total_verts += length(object.verts)
        total_uv += length(object.verts)
        total_objects += 1
    end
    println("total objects: $total_objects  total faces: $total_faces  total vertices: $total_verts  total normals: $total_normals ")
end


println("DONE")
