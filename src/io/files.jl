struct FileFormat{sym} end

struct File{Format <: FileFormat}
  io :: IO
end

macro format_str(format)
  FileFormat{Symbol(format)}
end

filespec = Tuple{Type{<:FileFormat},Vector{UInt8},String}[]

add_format(format, magicbytes, ext) = push!(filespec, (format, Vector{UInt8}(magicbytes), ext))
add_format(format, magicbytes::Vector{UInt8}, ext) = push!(filespec, (format, magicbytes, ext))

load(path; kwargs...) = open(path, "r") do io
  ext = splitext(path)[2]
  for (format, magicbytes, targetext) in filespec
    targetext == ext || continue
    seek(io, 0)
    read(io, length(magicbytes)) == magicbytes || continue
    seek(io, 0)
    return load(File{format}(io); kwargs...)
  end
end
