"""
`AbstractMesh{N,V<:AbstractPoint{N},F<:AbstractFace}`

Supertype for `N`-dimensional surface-mesh with faces of type `F` and `N`-dimensional vertices of type `V`

Each surface-mesh is collection of vertices and faces. Each face consists of vector of offsets into vertices vector.
"""
abstract type AbstractMesh{N,V <: AbstractPoint{N}, F <: AbstractPolygon} <: AbstractVector{F} end

Base.haslength(::AbstractMesh) = true
Base.eltype(::AbstractMesh{N,V,F}) where {N,V,F} = F
Base.IndexStyle(::Type{<:AbstractMesh}) = Base.IndexLinear()