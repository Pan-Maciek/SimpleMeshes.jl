add_format(format"PLY_ASCII", "ply\nformat ascii 1.0", ".ply")
add_format(format"PLY_BINARY", "ply\nformat binary_little_endian 1.0", ".ply")

function type(t) 
    if t == "float" return Float32
    else throw(ArgumentError("unexpected property type $t")) end
end

parseheader(io::IO, ::format"PLY_BINARY") = parseheader(io, format"PLY_ASCII"())
function parseheader(io::IO, ::format"PLY_ASCII")
    types, properties  = Type[], Symbol[]
    vertices, faces = 0, 0

    vertexmode = false
    line = readline(io)

    while !startswith(line, "end_header")
        if startswith(line, "e") # element *
            tmp = split(line)
            vertexmode = tmp[2] == "vertex"
            if vertexmode vertices = parse(Int, tmp[3])
            else faces = parse(Int, tmp[3]) end
        elseif startswith(line, "pr") && vertexmode # vertex property
            tmp = split(line)
            if !(tmp[3] in ["x", "y", "z"])
                push!(types, type(tmp[2]))
                push!(properties, Symbol(tmp[3]))
            end
        end
        line = readline(io)
    end

    if length(properties) == 0
        (vertices, faces, [], Tuple{}(), Point{3, Float32})
    else
        (vertices, faces, types, Tuple(properties),
        MetaPoint{3, Float32, Tuple(properties), Tuple{types...}})
    end
end

function load(file::File{format"PLY_ASCII"}; mesh=Mesh)
  io = file.io
  # read the header
  vertices, n_faces, types, properties, vertex = parseheader(io, format"PLY_ASCII"())

  points = Array{vertex}(undef, vertices)
  faces = Array{Triangle}(undef, n_faces)

  # read the data
  if length(types) == 0
    for i in 1:vertices 
        points[i] = vertex(Tuple(parse.(Float32, split(readline(io)))))
    end
  else
    for i in 1:vertices 
        tmp = split(readline(io))
        points[i] = vertex(
            Tuple(parse.(Float32, tmp[1:3])),
            NamedTuple{properties}(parse.(types, tmp[4:end])) # todo simplify meshes with metadata
        )
    end
  end

  for i = 1:n_faces
      line = split(readline(io))
      N = parse(Int, popfirst!(line))
      @assert N == 3
      faces[i] = Polygon{3}(parse.(UInt32, line))
  end
  mesh(points, faces)
end

function load(file::File{format"PLY_BINARY"}; mesh=Mesh)
    io = file.io
    # read the header
    vertices, n_faces, types, properties, vertex = parseheader(io, format"PLY_BINARY"())

    # read vertex data
    raw_vertices = read(io, sizeof(vertex) * vertices)
    
    # read face data
    faces = Array{Triangle}(undef, n_faces)
    for i = 1:n_faces
        N = read(io, UInt8)
        @assert N == 3
        faces[i] = read(io, Triangle) 
    end

    mesh(unsafe_wrap(Vector{vertex}, unsafe_convert(Ptr{vertex}, raw_vertices), vertices), faces)
end