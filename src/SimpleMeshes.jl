module SimpleMeshes

using OffsetArrays
using LinearAlgebra
using DataStructures

include("points.jl")
include("faces.jl")

include("meshes/base.jl")
include("meshes/mesh.jl")
include("meshes/halfedge.jl")

include("utils.jl")

include("io/files.jl")
include("io/ply.jl")

include("lab1.jl")

export AbstractPoint, Point, MetaPoint,
  AbstractPolygon, Polygon, Triangle,
  AbstractMesh, Mesh, TriangleMesh, HalfEdgeMesh,
  face, vertex, edges,
  File, FileFormat, format_str, add_format, load,
  faceswith, vneighbors, fneighbors, traverse, flipdiag!

end
