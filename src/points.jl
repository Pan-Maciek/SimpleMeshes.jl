"""
`AbstractPoint{N,T} <: AbstractVector{T}`

Supertype for fixedsize `N`-dimensional points with elements of type `T`.
"""
abstract type AbstractPoint{N,T} <: AbstractVector{T} end

Base.haslength(::AbstractPoint) = true
Base.length(::AbstractPoint{N}) where N = N
Base.size(::AbstractPoint{N}) where N = (N,)
Base.eltype(::AbstractPoint{N,T}) where {N,T} = T
Base.IndexStyle(::Type{<:AbstractPoint}) = Base.IndexLinear()

"""
`Point{N,T} <: AbstractPoint{N,T}`

Fixedsize `N`-dimensional point with elements of type `T`.
"""
struct Point{N,T} <: AbstractPoint{N,T} 
  data :: NTuple{N,T}
end

function Point(x, y) 
  values = promote(x, y)
  Point{2,eltype(values)}(values)
end

function Point(x, y, z) 
  values = promote(x, y, z)
  Point{3,eltype(values)}(values)
end

using Base: unsafe_load, unsafe_convert

Point{N,T}(vec::Vector{T}) where {N,T} = 
  unsafe_load(unsafe_convert(Ptr{Point{N,T}}, vec))

Base.getindex(point::Point, i) = point.data[i]

struct MetaPoint{N,T,A,M} <: AbstractPoint{N,T}
  data :: NTuple{N,T}
  meta :: NamedTuple{A,M}
end

Base.getindex(point::MetaPoint, i) = point.data[i]
Base.getindex(point::MetaPoint, sym::Symbol) = point.meta[sym]
meta(point::MetaPoint) = point.meta