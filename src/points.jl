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

const Point2{T} = Point{2,T}
const Point3{T} = Point{3,T}

const Point2f = Point{2,Float64}
const Point3f = Point{3,Float64}

function Point(x, y) 
  values = promote(x, y)
  Point{2,eltype(values)}(values)
end

function Point(x, y, z) 
  values = promote(x, y, z)
  Point{3,eltype(values)}(values)
end

Base.getindex(point::Point, i) = point.data[i]
