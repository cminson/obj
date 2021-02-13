#!/usr/local/bin/julia
#
# imagetrace
# convert image into line trace coordinates
#
# ref: https://www.youtube.com/watch?t=137&v=OuCiHp43q20&feature=youtu.be
# input: path to image (in png format)
# output: text file with line trace coordinates
#
# author: Christopher Minson
#

#using Pkg
#Pkg.add("Images")

using Images, ImageIO, FileIO

const THRESHOLD = 0.5
ErrorAccumulator = 0.0

#=
function halftone(pixel_value)

    global ErrorAccumulator
    #ErrorAccumulator = 0
    pixel_value = pixel_value + ErrorAccumulator

    if pixel_value < THRESHOLD
        new_pixel_value = 0.0
    else
        new_pixel_value = 1.0
    end

    ErrorAccumulator = ErrorAccumulator + THRESHOLD - pixel_value
    return new_pixel_value
end
=#

function halftone(pixel_value)

    global ErrorAccumulator

    pixel_value += ErrorAccumulator

    if pixel_value < THRESHOLD
        new_pixel_value = 0.0
    else
        new_pixel_value = 1.0
    end

    ErrorAccumulator += THRESHOLD - pixel_value
    return new_pixel_value
end


#
# main entry
#
if length(ARGS) != 1
    println("usage: $PROGRAM_FILE <path input image>")
    exit()
end

path_input = ARGS[1]
if isfile(path_input) == false
    println("ERROR:  image \"$path_input\" not found")
    exit()
end
path_output = replace(path_input, ".png" => ".txt")
println("Converting $path_input ...")
    
img = load(path_input)
gray_image = Gray.(img)
save("test01.png", gray_image)
half_tone_image = halftone.(gray_image)
save("test02.png", half_tone_image)


println("Output stored in $path_output")
println("Complete")
