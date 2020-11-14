"""
`AbstractPolygon{N}`

Supertype for `N`-vertices polygon.
"""
abstract type AbstractPolygon{N} <: AbstractVector{N} end

Base.haslength(::Type{AbstractPolygon}) = false
Base.haslength(::Type{<:AbstractPolygon{N}}) where N = true
Base.length(::Type{<:AbstractPolygon{N}}) where N = N

Base.haslength(::AbstractPolygon{N}) where N = true
Base.length(::AbstractPolygon{N}) where N = N
Base.size(::AbstractPolygon{N}) where N = (N,)
Base.eltype(::AbstractPolygon) = UInt32
Base.IndexStyle(::Type{<:AbstractPolygon}) = Base.IndexLinear()

"""
`Polygon{N} <: AbstractPolygon{N}`

Fixedsize polygon with `N`-vertices representing offset into zeroindexed vertex array.
"""
struct Polygon{N} <: AbstractPolygon{N}
  data :: NTuple{N,UInt32}
end

Polygon{L}(array::Array) where L = Polygon{L}((array...,))
Base.getindex(polygon::Polygon, i) = polygon.data[i]

"""
`Triangle <: AbstractPolygon{3}`

Alias for `Polygon{3}`
"""
const Triangle = Polygon{3}
Triangle(a,b,c) = Polygon{3}((a,b,c))

edges(poly::Polygon{N}) where N = [(poly[i], poly[i%N+1]) for i in 1:N] 