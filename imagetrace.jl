#!/usr/local/bin/julia
#
# imagetrace
# convert image into line trace coordinates
#
# ref: https://www.youtube.com/watch?t=137&v=OuCiHp43q20&feature=youtu.be
# input: path to image (in png format)
# output: text file (PATH_OUTPUT) with line trace coordinates
#
# author: Christopher Minson
#

using Images, ImageIO, FileIO

struct Point
    row
    col
end

const THRESHOLD = 0.5
const SIZE_CELL = 16
const PATH_OUTPUT = "data.txt"

ErrorAccumulator = 0.0
TraceCoordinates = []


# binary-tone an array
function halftone(pixel_value)

    global ErrorAccumulator

    pixel_value += ErrorAccumulator

    if pixel_value < THRESHOLD
        new_pixel_value = 1.0
    else
        new_pixel_value = 0.0
    end

    ErrorAccumulator += THRESHOLD - pixel_value
    return new_pixel_value
end


# return point closest to current_point, in given cell
function get_next_point(current_point, cell)

    min_distance = typemax(Int32)
    next_point = current_point
    
    for row in 1:SIZE_CELL
        for col in 1:SIZE_CELL
            if cell[row,col] == 0 continue end
            point = Point(row, col)
            distance = sqrt((current_point.row - point.row)^2 + (current_point.col - point.col)^2)

            if distance < min_distance
                min_distance = distance
                #position_row = point.row + ((offset_row - 1) * SIZE_CELL)
                #position_col = point.col + ((offset_col - 1) * SIZE_CELL)
                #next_point = Point(position_row, position_col)
                next_point = point
            end
        end
    end
    return next_point
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
    
img = load(path_input)
size_image = size(img)
println("Converting $path_input $size_image...")
gray_image = Gray.(img)
half_tone_image = halftone.(gray_image)

cell_row_count = Int(floor(size_image[1] / SIZE_CELL))
cell_col_count = Int(floor(size_image[2] / SIZE_CELL))

#
# generate trace coordinates
#
output_fd = open(PATH_OUTPUT, "w+")
CurrentPoint = Point(1,1)
NextPoint = Point(1,1)
write(output_fd,"1,1 ")
for cell_row in 1:cell_row_count
    for cell_col in 1:cell_col_count
        row = ((cell_row - 1) * SIZE_CELL) + 1
        col = ((cell_col - 1) * SIZE_CELL) + 1

        cell = half_tone_image[row:row+SIZE_CELL-1,col:col+SIZE_CELL-1] 
        if sum(cell) == 0 continue end  

        for i in 1:SIZE_CELL*SIZE_CELL
            cell[CurrentPoint.row,CurrentPoint.col] = 0 
            global NextPoint = get_next_point(CurrentPoint, cell)
            if NextPoint == CurrentPoint break end
            global CurrentPoint = NextPoint
            position_row = CurrentPoint.row + row
            position_col = CurrentPoint.col + col
            write(output_fd,"$position_row,$position_col ")
        end
    end
end
close(output_fd)


println("Output stored in $PATH_OUTPUT")
println("Complete")
