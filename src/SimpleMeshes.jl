module SimpleMeshes

using OffsetArrays
using LinearAlgebra

include("utils.jl")
include("points.jl")
include("faces.jl")
include("meshes.jl")

export AbstractPoint, Point, Point2, Point2f, Point3, Point3f,
  AbstractPolygon, Polygon, Triangle,
  AbstractMesh, Mesh, TriangleMesh, 
  faceswith, vneighbors, fneighbors, traverse, flipdiag!

end
