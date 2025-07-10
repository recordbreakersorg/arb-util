
function (@main)(args::Vector{String})::Cint
  println(Core.stdout, "Hello, world!")
  ccall(:system, Cint, (Cstring,), "echo Hello")
  return 0
end
