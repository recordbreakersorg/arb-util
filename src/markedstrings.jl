function extractmarkedstringsinfile(file::String)::Channel{Tuple{String,String}}
  Channel{Tuple{String,String}}() do channel
    while true
      found = false
      for (lineidx, line) in enumerate(open(readlines, file))
        m = match(r"_\"[^\"]+\"", line)
        isnothing(m) && continue
        normalized = normalizedtranslationname(m.match)
        put!(channel, (normalized, m.match[2:end]))
        println(Core.stdout, "Replacing $normalized in $file")
        replacetranslation(file, normalized, m.match)
        found = true
        break
      end
      !found && break
    end
  end
end

function replacetranslation(file::AbstractString, normal::String, text::AbstractString)
  content = open(file) do f
    read(f, String)
  end
  content = replace(content, text => gentranslationcaller(normal))
  open(file, "w") do f
    write(f, content)
  end
end
gentranslationcaller(name::String) = "AppLocalizations.of(context)!.$name"


function extractmarkedstrings(project::FlutterProject)::Channel{Tuple{String,String}}
  Channel{Tuple{String,String}}() do channel
    for (folder, _, files) ∈ walkdir(joinpath(project.root, "lib/"))
      for file in files
        if endswith(file, ".dart") && !endswith(folder, "l10n")
          for tup in extractmarkedstringsinfile(joinpath(folder, file))
            put!(channel, tup)
          end
        end
      end
    end
  end
end
