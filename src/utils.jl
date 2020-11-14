zerobased(array::Vector) = OffsetVector(array, 0:length(array)-1)
midpoint(A, B) = (A .+ B) ./ 2.

function facenorm(mesh::Mesh, faceidx)
  @inbounds A, B, C = vertex(mesh, [face(mesh, faceidx)[1:3]...])
  normalize((B .- A) × (C .- A))
end

function facenorm(mesh::HalfEdgeMesh, faceidx)
  h = mesh.halfedges[mesh.faces[faceidx]]
  @inbounds A, B, C = vertex(mesh, [
    mesh.halfedges[h.prev].origin,
    h.origin,
    mesh.halfedges[h.next].origin
  ])
  normalize((B .- A) × (C .- A))
end