#!/usr/local/bin/julia

#using ArgParse


#
# Main
#
println("USD")
println(PROGRAM_FILE); 
for x in ARGS 
    println(x); 
    end


const SCALE = 1
const SUB_DIVISIONS = 1
const NAME = "SPHERE"
const PHI = Float64((1 + sqrt(5)) / 2)   # golden ratio

PATH_OBJ_FILE = "./test.obj"

middle_point_cache = Dict()

function vertex(x::Float64, y::Float64, z::Float64)

    len = sqrt(x^2 + y^2 + z^2)
    return [(i * SCALE) / len for i in (x,y,z)]
end


function middle_point(point1, point2)

    #println("$point1 $point2")
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

    println("$vert1 $vert2 $middle")
    push!(Verts, vertex(middle[1], middle[2], middle[3]))

    len_verts = length(Verts)
    middle_point_cache[key] = len_verts

    return len_verts

end


Verts = [ 
    vertex(-1.0, PHI, 0.0), 
    vertex( 10.0, PHI, 0.0),
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
                                                   
                                                   

for i in 1:SUB_DIVISIONS

    faces_subdiv = [] 
    for tri in FACES 
        #println(tri[1], tri[2])
        v1 = middle_point(tri[1], tri[2]) 
        v2 = middle_point(tri[2], tri[3]) 
        v3 = middle_point(tri[3], tri[1]) 
        push!(faces_subdiv,([tri[1], v1, v3])) 
        push!(faces_subdiv,([tri[2], v2, v1]))
        push!(faces_subdiv,([tri[3], v3, v2]))
        push!(faces_subdiv,([v1, v2, v3])) 
    end
    faces = faces_subdiv

end

open(PATH_OBJ_FILE, "w+") do f

    write(f, "#\n#\n")
    write(f, "# Object File Test\n")
    write(f, "#\n#\n")
    write(f, "o atomtest\n")
    for verts in Verts
        x = round(verts[1], digits=6)
        y = round(verts[2], digits=6)
        z = round(verts[3], digits=6)
        write(f, "v $x $y $z\n")
    end

end

for x in 1:2
    println("X = $x")
end
                                                   

println("DONE")
