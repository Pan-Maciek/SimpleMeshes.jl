"""
`AbstractMesh{N,V<:AbstractPoint{N},F<:AbstractFace}`

Supertype for `N`-dimensional surface-mesh with faces of type `F` and `N`-dimensional vertices of type `V`
"""
abstract type AbstractMesh{N,V <: AbstractPoint{N}, F <: AbstractPolygon} end

struct Mesh{N,V,F} <: AbstractMesh{N,V,F}
  vertices :: OffsetVector{V}
  faces :: OffsetVector{F}
end

Mesh(vertices::Vector{V}, faces::Vector{F}) where {V,F} = 
  Mesh{3,V,F}(zerobased(vertices), zerobased(faces))

const TriangleMesh{N,V} = Mesh{N,V,Triangle}

# OP1
"""
`faceswith(mesh::Mesh, idx)`

Return a vector `I` of the indices of faces containing vertex with given `idx`.
"""
faceswith(mesh::Mesh, idx) = 
  findall(face -> idx in face, mesh.faces)

# OP2
"""
`vneighbors(mesh::Mesh, idx; depth=1)`
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

# OP3
"""
`fneighbors(mesh::Mesh, idx; depth=1)`
"""
function fneighbors(mesh::Mesh, idx; depth=1)
  neighbors = Set{UInt32}()
  distance = zerobased(fill(depth + 1, length(mesh.vertices)))
  usedfaces = fill(false, length(mesh.faces))

  for v in mesh.faces[idx]
    distance[v] = 0
  end
  usedfaces[idx+1] = true 

  for depth in 1:depth, (i, face) in enumerate(mesh.faces)
    usedfaces[i] && continue
    dist = sort(map(v -> distance[v], face))
    if dist[2] < depth # works only for triangles
      usedfaces[i] = true
      push!(neighbors, i-1)
      for v in face
        distance[v] = min(distance[v], dist[2] + 1) # works only for triangles
      end
    end
  end
  delete!(neighbors, idx)

  collect(neighbors)
end

# OP4
"""
"""
traverse(mesh::Mesh{3,Point}, faceidx, target::Point) where Point = 
Channel{Int32}() do channel
  # compute surface norms
  facenorms = map(face -> facenorm(mesh, face), eachindex(mesh.faces))
  usedfaces = zerobased(fill(false, length(mesh.faces)))

  @inbounds while true
    @label start
    usedfaces[faceidx] && break
    usedfaces[faceidx] = true
    face = mesh.faces[faceidx]
    put!(channel, faceidx) # yield

    # find all edges
    edgepoints = edges(mesh, faceidx)

    # compute edge norms
    edgenorms = [normalize((T .- S) × facenorms[faceidx]) for (S, T) in edgepoints]
    # compute directional vecotrs
    dirs = [normalize(target .- midpoint(S, T)) for (S, T) in edgepoints]

    # compute dot products
    dotprods = [e ⋅ d for (e, d) in zip(edgenorms, dirs)] # e,d normalized
    # find smallest angle
    ord = sortperm(dotprods; rev=true) # cosθ₁ < cosθ₂ => θ₁ > θ₂

    dotprods[ord[1]] <= 0 && break # point is inside the current face
    for v in ord
      S, T = face[[v, v % 3 + 1]]
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
function flipdiag!(mesh::TriangleMesh, Aidx, Bidx)
  A = mesh.faces[Aidx]
  B = mesh.faces[Bidx]

  olddiag = A ∩ B
  newdiag = (setdiff(A, olddiag)[1], setdiff(B, olddiag)[1])

  mesh.faces[Aidx] = SA[newdiag[1], newdiag[2], olddiag[1]]
  mesh.faces[Bidx] = SA[olddiag[2], newdiag[2], newdiag[1]]
  newdiag
end

function facenorm(mesh::Mesh, faceidx)
  face = mesh.faces[faceidx]
  A, B, C = mesh.vertices[face]
  normalize((B .- A) × (C .- A))
end

function edges(mesh::TriangleMesh, faceidx)
  face = mesh.faces[faceidx]
  A, B, C = mesh.vertices[face]
  [(A, B), (B, C), (C, A)]
end

midpoint(A, B) = (A .+ B) ./ 2.