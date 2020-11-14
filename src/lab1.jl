# OP1
"""
`faceswith(mesh::Mesh, idx)`

Return a vector `I` of the indices of faces containing vertex with given `idx`.
"""
faceswith(mesh::Mesh, idx) = 
  findall(face -> idx in face, mesh.faces)

function faceswith(mesh::HalfEdgeMesh, idx)
  faces = UInt32[]
  itersameorigin(mesh, idx) do edge
    push!(faces, edge.face)
  end
  faces
end

# OP2
"""
`vneighbors(mesh::Mesh, idx; depth=1)`

Return a vector `I` containing the indices of vertices surrounding vertex with given `idx`.
"""
function vneighbors(mesh::Mesh, idx; depth=1)
  neighbors = Set{UInt32}()
  distance = zerobased(fill(depth + 1, length(mesh.vertices)))
  usedfaces = fill(false, length(mesh.faces))
  distance[idx] = 0

  for depth in 1:depth, (i, face) in enumerate(mesh.faces)
    usedfaces[i] && continue
    dist = minimum(v -> distance[v], face)
    if dist < depth
      usedfaces[i] = true
      for v in face
        distance[v] = min(distance[v], dist + 1) # works only for triangles
        push!(neighbors, v)
      end
    end
  end
  delete!(neighbors, idx)

  collect(neighbors)
end

function vneighbors(mesh::HalfEdgeMesh, idx; depth=1)
  neighbors = Set{UInt32}()
  distance = zerobased(fill(depth + 1, length(mesh.vertices)))
  distance[idx] = 0

  queue = Queue{UInt32}()
  enqueue!(queue, idx)
  while !isempty(queue)
    idxv = dequeue!(queue)
    itersameorigin(mesh, idxv) do edge
      for vert in (mesh.halfedges[edge.next].origin, mesh.halfedges[edge.prev].origin)
        if distance[idxv] + 1 < distance[vert]
          distance[vert] = distance[idxv] + 1
          push!(neighbors, vert)
          if distance[vert] != depth
            enqueue!(queue, vert)
          end
        end
      end
    end
  end
  delete!(neighbors, idx)

  collect(neighbors)
end

# OP3
"""
`fneighbors(mesh::Mesh, idx; depth=1)`

Return a vector `I` containing the indices of faces surrounding face with given `idx`.
"""
function fneighbors(mesh::TriangleMesh, idx; depth=1)
  neighbors = Set{UInt32}()
  distance = zerobased(fill(depth + 1, length(mesh.vertices)))
  usedfaces = fill(false, length(mesh.faces))

  distance[face(mesh, idx)] .= 0
  usedfaces[idx] = true 

  for depth in 1:depth, (i, face) in enumerate(mesh.faces)
    usedfaces[i] && continue
    dist = sort(map(v -> distance[v], face))
    if dist[2] < depth
      usedfaces[i] = true
      push!(neighbors, i)
      for v in face
        distance[v] = min(distance[v], dist[2] + 1) # works only for triangles
      end
    end
  end
  delete!(neighbors, idx)

  collect(neighbors)
end

function fneighbors(mesh::HalfEdgeMesh, idx; depth=1)
  neighbors = Set{UInt32}()
  distance = fill(depth + 1, length(mesh.faces))
  distance[idx] = 0

  queue = Queue{UInt32}()
  enqueue!(queue, idx) 
  while !isempty(queue)
    facev = dequeue!(queue)
    itersameface(mesh, facev) do edge
      edge.twin != 0 || return # next edge
      twin = mesh.halfedges[edge.twin].face
      if distance[facev] + 1 < distance[twin]
        distance[twin] = distance[facev] + 1
        push!(neighbors, twin)
        if distance[twin] != depth
          enqueue!(queue, twin)
        end
      end
    end
  end
  delete!(neighbors, idx)

  collect(neighbors)
end

# OP4
"""
`traverse(mesh::Mesh{3,Point})`
"""
traverse(mesh::Mesh{3,Point}, faceidx, target::Point) where Point = 
Channel{Int32}() do channel
  # compute surface norms
  usedfaces = fill(false, length(mesh.faces))

  @inbounds while true
    @label start
    usedfaces[faceidx] && break
    usedfaces[faceidx] = true
    facev = face(mesh, faceidx)
    put!(channel, faceidx) # yield

    # find all edges
    edgepoints = [(vertex(mesh, S), vertex(mesh, T)) for (S, T) in edges(facev)]

    # compute edge norms
    edgenorms = [normalize((T .- S) × facenorm(mesh, faceidx)) for (S, T) in edgepoints]
    # compute directional vecotrs
    dirs = [normalize(target .- midpoint(S, T)) for (S, T) in edgepoints]

    # compute dot products
    dotprods = [e ⋅ d for (e, d) in zip(edgenorms, dirs)] # e,d normalized
    # find smallest angle
    ord = sortperm(dotprods; rev=true) # cosθ₁ < cosθ₂ => θ₁ > θ₂

    dotprods[ord[1]] <= 0 && break # point is inside the current face
    for v in ord
      S, T = facev[[v, v % 3 + 1]]
      # check if edge has neighbouring face
      for newfaceidx in eachindex(mesh.faces)
        (newfaceidx == faceidx || usedfaces[newfaceidx]) && continue
        newface = mesh.faces[newfaceidx]
        if S in newface && T in newface
          faceidx = newfaceidx
          @goto start
        end
      end
    end
  end
end

# OP5
"""
`flipdiag!(mesh::AbstractMesh{N,V,Triangle}, faceidx₁, faceidx₂)`
"""
function flipdiag!(mesh::TriangleMesh, Aidx, Bidx)
  A = face(mesh, Aidx)
  B = face(mesh, Bidx)

  olddiag = A ∩ B
  @assert length(olddiag) == 2 "Face $Aidx should have exacly one edge in common with face $Bidx."

  newdiag = (setdiff(A, olddiag)[1], setdiff(B, olddiag)[1])

  mesh.faces[Aidx] = Triangle(newdiag[1], newdiag[2], olddiag[1])
  mesh.faces[Bidx] = Triangle(olddiag[2], newdiag[2], newdiag[1])
  newdiag
end


# OP4
traverse(mesh::HalfEdgeMesh{3,Point}, faceidx, target::Point) where Point = 
Channel{Int32}() do channel
  usedfaces = fill(false, length(mesh.faces))

  @inbounds while true
    usedfaces[faceidx] && break
    usedfaces[faceidx] = true
    halfedges, facev = face(mesh, faceidx; keephalfedges=true)
    put!(channel, faceidx) # yield

    # find all edges
    edgepoints = [(vertex(mesh, S), vertex(mesh, T)) for (S, T) in edges(facev)]

    # compute edge norms
    edgenorms = [normalize((T .- S) × facenorm(mesh, faceidx)) for (S, T) in edgepoints]
    # compute directional vecotrs
    dirs = [normalize(target .- midpoint(S, T)) for (S, T) in edgepoints]

    # compute dot products
    dotprods = [e ⋅ d for (e, d) in zip(edgenorms, dirs)] # e,d normalized
    # find smallest angle
    ord = sortperm(dotprods; rev=true) # cosθ₁ < cosθ₂ => θ₁ > θ₂

    dotprods[ord[1]] <= 0 && break # point is inside the current face
    for v in ord
      edge = halfedges[v]
      # check if edge has neighbouring face
      twin = mesh.halfedges[edge].twin
      twin == 0 && continue
      newfaceidx = mesh.halfedges[twin].face
      (newfaceidx == faceidx || usedfaces[newfaceidx]) && continue
      faceidx = newfaceidx
      break
    end
  end
end

# OP5
function flipdiag!(mesh::HalfEdgeMesh{N,V,Triangle}, Aidx, Bidx) where {N,V}
  # find common edge
  start = ait = mesh.faces[Aidx]
  found = false
  while ait != start
    edge = mesh.halfedges[ait]
    if edge.twin != 0 && mesh.halfedges[edge.twin].face == Bidx
      found = true
      break
    end
    ait = edge.next
  end

  @assert found "Face $Aidx should have exacly one edge in common with face $Bidx."

  # swap
  @inbounds begin
    bit = mesh.halfedges[ait].twin

    Aprev = mesh.halfedges[ait].prev
    Bprev = mesh.halfedges[bit].prev

    Anext = mesh.halfedges[ait].next
    Bnext = mesh.halfedges[bit].next

    mesh.vertexhalfedge[meshes.halfedges[ait].origin] = Bnext
    mesh.vertexhalfedge[meshes.halfedges[bit].origin] = Anext

    mesh.halfedges[ait].origin = mesh.halfedges[Aprev].origin
    mesh.halfedges[bit].origin = mesh.halfedges[Bprev].origin

    A = (Anext, ait, Bprev, Anext, ait)
    B = (Bnext, bit, Aprev, Bnext, bit)

    for i in 2:4
      mesh.halfedges[A[i]].next = A[i+1]
      mesh.halfedges[A[i]].prev = A[i-1]
      mesh.halfedges[B[i]].next = B[i+1]
      mesh.halfedges[B[i]].prev = B[i-1]
    end

    mesh.halfedges[Bprev].face = Aidx
    mesh.halfedges[Aprev].face = Bidx

    mesh.faces[Aidx] = ait
    mesh.faces[Bidx] = bit

    (mesh.halfedges[ait].origin, mesh.halfedges[bit].origin)
  end
end