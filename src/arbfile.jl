struct ArbFile
  path::String
end
arbfile(path::String) = ArbFile(path)

function readfile(file::ArbFile)::Dict{String, String}
  f = open(file.path)
  local data::Dict{String, String}
  try
    data = JSON.parse(read(f, String), dicttype=Dict{String, String})
  finally
    close(f)
  end
  return data
end

function writefile(file::ArbFile, data::Dict{String, String})
  serial = JSON.json(data, 2)
  f = open(file.path, "w")
  try
    write(f, serial)
  finally
    close(f)
  end
end

function hastranslation(arb::ArbFile, key::String)
  key in keys(readfile(arb))
end

function addtranslation!(arb::ArbFile, key::String, value::String)
  data = readfile(arb)
  data[key] = value
  writefile(arb, data)
end

function copymissingkeys(from::ArbFile, to::ArbFile)
  data1 = readfile(from)
  data2 = readfile(to)
  missingkeys::Set{String} = setdiff(keys(data1), keys(data2))
  for key in missingkeys
    println(Core.stdout, "Adding missing $key to $(to.path)")
    addtranslation!(to, key, "#" * data1[key])
  end
end

function normalizedtranslationname(string::AbstractString)::String
  normal::String = ""
  upper::Bool = false
  for c in collect(string)
    if c == ' '
      upper = true
    elseif isletter(c)
      normal *= upper ? uppercase(c) : lowercase(c)
      upper = false
    elseif isdigit(c)
      normal *= c
      upper = false
    end
  end
  return normal
end
