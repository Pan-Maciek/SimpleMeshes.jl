module SimpleMeshes

using OffsetArrays
using LinearAlgebra

include("points.jl")
include("faces.jl")

include("meshes/base.jl")
include("meshes/mesh.jl")
include("meshes/halfedge.jl")

include("utils.jl")

include("io/files.jl")
include("io/ply.jl")

export AbstractPoint, Point, Point2, Point2f, Point3, Point3f,
  AbstractPolygon, Polygon, Triangle,
  AbstractMesh, Mesh, TriangleMesh, HalfEdgeMesh,
  face, vertex, edges,
  File, FileFormat, format_str, add_format, load

end
