include("ArbUtil.jl")
using JSON
using .ArbUtil

function @main(args::Vector{String})::Cint
  root = length(args) > 1 ? args[2] : "."
  project = ArbUtil.FlutterProject(root)
  ArbUtil.watchchanges(project)
  0
end
