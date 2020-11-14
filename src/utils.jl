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

function itersameorigin(f, mesh::HalfEdgeMesh, idx)
  startedge = mesh.halfedges[mesh.vertexhalfedge[idx]]
  startface = startedge.face
  # rotate clockwise
  edge = startedge
  f(edge)
  @inbounds while edge.twin != 0
    edge = mesh.halfedges[mesh.halfedges[edge.twin].next]
    edge.face == startface && return # loop detected
    f(edge)
  end
  # rotate counterclockwise
  edge = mesh.halfedges[startedge.prev]
  @inbounds while edge.twin != 0
    edge = mesh.halfedges[edge.twin]
    f(edge)
    edge = mesh.halfedges[edge.prev]
  end
  return
end

function itersameface(f, mesh::HalfEdgeMesh, idx)
  start = mesh.faces[idx]
  edge = mesh.halfedges[start]
  @inbounds while edge.next != start
    f(edge)
    edge = mesh.halfedges[edge.next]
  end
  f(edge)
  return
end