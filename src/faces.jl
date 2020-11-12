"""
`AbstractPolygon{N}`

Supertype for `N`-vertices polygon.
"""
abstract type AbstractPolygon{N} <: AbstractVector{N} end

Base.haslength(::AbstractPolygon) = true
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

Base.getindex(polygon::Polygon, i) = polygon.data[i]

"""
`Triangle <: AbstractPolygon{3}`

Alias for `Polygon{3}`
"""
const Triangle = Polygon{3}
Triangle(a,b,c) = Polygon{3}((a,b,c))
