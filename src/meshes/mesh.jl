"""
`Mesh{N,V,F} <: AbstractMesh{N,V,F}`

`N`-dimensional surface-mesh with faces of type `F` and `N`-dimensional vertices of type `V`

Mesh(vertices::Vector{<:AbstractPoint}, faces::Vector{<:AbstractPolygon})
"""
struct Mesh{N,V,F} <: AbstractMesh{N,V,F}
  vertices :: OffsetVector{V}
  faces :: Vector{F}
end

"""
`TriangularMesh{N,V}`

`N`-dimensional surface-mesh with triangular faces and `N`-dimensional vertices of type `V`
"""
const TriangleMesh{N,V} = Mesh{N,V,Triangle}

Mesh(vertices::Vector{V}, faces::Vector{F}) where {N,V<:AbstractPoint{N},F} = 
  Mesh{N,V,F}(zerobased(vertices), faces)

face(mesh::Mesh, i) = mesh.faces[i]
vertex(mesh::Mesh, i) = mesh.vertices[i]

Base.length(mesh::Mesh) = length(mesh.faces)
Base.size(mesh::Mesh) = size(mesh.faces)
Base.getindex(mesh::Mesh, i) = face(mesh, i)
