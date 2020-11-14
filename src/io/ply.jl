add_format(format"PLY_ASCII", "ply\nformat ascii 1.0", ".ply")
add_format(format"PLY_BINARY", "ply\nformat binary_little_endian 1.0", ".ply")

function load(file::File{format"PLY_ASCII"}; mesh=Mesh)
  io = file.io
  n_points = 0
  n_faces = 0

  # read the header
  line = readline(io)

  while !startswith(line, "end_header")
      if startswith(line, "element vertex")
          n_points = parse(Int, split(line)[3])
      elseif startswith(line, "element face")
          n_faces = parse(Int, split(line)[3])
      end
      line = readline(io)
  end

  points = Array{Point3f}(undef, n_points)
  faces = Array{Triangle}(undef, n_faces)

  # read the data
  for i = 1:n_points
      points[i] = Point(parse.(Float64, split(readline(io)))...)
  end

  for i = 1:n_faces
      line = split(readline(io))
      len = parse(Int, popfirst!(line))
      faces[i] = Triangle(parse.(UInt32, line)...)
  end
  mesh(points, faces)
end

function load(file::File{format"PLY_BINARY"}; mesh=Mesh)
    io = file.io
    n_points = 0
    n_faces = 0

    properties = String[]

    # read the header
    line = readline(io)

    while !startswith(line, "end_header")
        if startswith(line, "element vertex")
            n_points = parse(Int, split(line)[3])
        elseif startswith(line, "element face")
            n_faces = parse(Int, split(line)[3])
        end
        line = readline(io)
    end

    points = Array{Point{3,Float32}}(undef, n_points)
    faces = Array{Triangle}(undef, n_faces)

    # read the data
    for i = 1:n_points
        points[i] = Point{3,Float32}((read(io, Float32), read(io, Float32), read(io, Float32)))
    end

    for i = 1:n_faces
        len = read(io, UInt8)
        faces[i] = Triangle([ read(io, UInt32) for _ in 1:len ]...)
    end
    mesh(points, faces)
end