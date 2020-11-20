struct FileFormat{sym} end

struct File{Format <: FileFormat}
  io :: IO
end

macro format_str(format)
  FileFormat{Symbol(format)}
end

filespec = Tuple{Type{<:FileFormat},Function,String}[]

add_format(format, test::Function, ext) = push!(filespec, (format, test, ext))
function add_format(format, magicbytes::Vector{UInt8}, ext) 
  len = length(magicbytes)
  test = io -> read(io, len) == magicbytes
  push!(filespec, (format, test, ext))
end
function add_format(format, magictext::String, ext)
  lines = split(magictext, r"\r?\n")
  test = io -> all(readline(io) == line for line in lines)
  push!(filespec, (format, test, ext))
end

load(path; kwargs...) = open(path, "r") do io
  ext = splitext(path)[2]
  for (format, test, targetext) in filespec
    targetext == ext || continue
    seekstart(io)
    test(io) || continue
    seekstart(io)
    return load(File{format}(io); kwargs...)
  end
end
