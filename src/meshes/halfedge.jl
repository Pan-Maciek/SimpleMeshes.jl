mutable struct HalfEdge 
  origin :: UInt32
  face :: UInt32
  twin :: UInt32
  next :: UInt32
  prev :: UInt32
end

struct HalfEdgeMesh{N,V,F} <: AbstractMesh{N,V,F}
  vertices :: OffsetVector{V}
  vertexhalfedge :: OffsetVector{UInt32} # contains offset into halfedges
  halfedges :: Vector{HalfEdge} # all halfedges
  faces :: Vector{UInt32}
end

function HalfEdgeMesh(vertices::Vector{V}, faces::Vector{F}) where {N,M,V<:AbstractPoint{N},F<:AbstractPolygon{M}}
  halfedgecount = length(faces) * M
  halfedges = Array{HalfEdge}(undef, halfedgecount)
  meshfaces = Array{UInt32}(undef, length(faces))
  edgedict = Dict{NTuple{2, UInt32}, UInt32}()
  vertexhalfedge = zerobased(Array{UInt32}(undef, length(vertices)))

  idx = 1
  for (faceidx, face) in enumerate(faces)
    meshfaces[faceidx] = idx
    for (S, T) in edges(face)
      if haskey(edgedict, (T, S))
        twinidx = edgedict[(T, S)]
        halfedges[idx] = HalfEdge(S, faceidx, twinidx, idx + 1, idx - 1)
        halfedges[twinidx].twin = idx
        delete!(edgedict, (T, S))
      else
        halfedges[idx] = HalfEdge(S, faceidx, 0, idx + 1, idx - 1)
        edgedict[(S, T)] = idx
        vertexhalfedge[S] = idx
      end
      idx += 1
    end
    halfedges[meshfaces[faceidx]].prev = idx - 1
    halfedges[idx - 1].next = meshfaces[faceidx]
  end

  HalfEdgeMesh{N,V,F}(zerobased(vertices), vertexhalfedge, halfedges, meshfaces)
end

function face(mesh::HalfEdgeMesh{N,V,F}, i; keephalfedges=false) where {M,F<:AbstractPolygon{M},N,V}
  idx = mesh.faces[i]
  vertices = Array{UInt32}(undef, M)
  if keephalfedges
    halfedges = Array{UInt32}(undef,M)
    @inbounds for i in 1:M
      halfedges[i] = idx
      vertices[i] = mesh.halfedges[idx].origin
      idx = mesh.halfedges[idx].next
    end
    (halfedges, F(vertices))
  else
    @inbounds for i in 1:M
      vertices[i] = mesh.halfedges[idx].origin
      idx = mesh.halfedges[idx].next
    end
    F(vertices)
  end
end
vertex(mesh::HalfEdgeMesh, i) = mesh.vertices[i]

Base.length(mesh::HalfEdgeMesh) = length(mesh.faces)
Base.size(mesh::HalfEdgeMesh) = size(mesh.faces)
Base.getindex(mesh::HalfEdgeMesh, i) = face(mesh, i)
