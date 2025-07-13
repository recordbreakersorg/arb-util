struct FlutterProject
  root::String
end
function getarbfiles(project::FlutterProject)::Channel{ArbFile}
  Channel{ArbFile}() do channel
    for file ∈ collect(walkdir(translationsdir(project)))[1][3]
      if startswith(file, "app") && endswith(file, ".arb")
        put!(channel, arbfile(joinpath(translationsdir(project), file)))
      end
    end
  end
end
function rebuildLocalizations(project)
  cmd = "flutter gen-l10n --project-dir=$(project.root)"
  @ccall system(cmd::String)::Int
end
function synchronizearbfiles(project::FlutterProject)
  files::Vector{ArbFile} = collect(getarbfiles(project))
  for file1 in files, file2 in files
    file1 == file2 && continue
    copymissingkeys(file1, file2)
  end
end

function addtranslationkey(project::FlutterProject, normalized::String, text::String)
  for arb in getarbfiles(project)
    if "en" ∈ arb.path
      !hastranslation(arb, normalized) && addtranslation!(arb, normalized, text)
    end
  end
end

translationsdir(project::FlutterProject) = joinpath(project.root, "lib/l10n")

function watchchanges(project::FlutterProject)
  println(Core.stdout, "Watching for changes...")
  mtimes = Dict{String,Float64}()
  while true
    shouldRefresh = false
    for (normalized, text) in extractmarkedstrings(project)
      addtranslationkey(project, normalized, JSON.parse(text))
      shouldRefresh = true
    end
    synchronizearbfiles(project)
    for file ∈ getarbfiles(project)
      if file.path ∉ keys(mtimes)
        println(Core.stdout, " - Adding file ", file.path)
        mtimes[file.path] = mtime(file.path)
      else
        modified = mtime(file.path)
        if modified > mtimes[file.path]
          println(Core.stdout, "File modified", last(splitdir(file.path)))
          mtimes[file.path] = modified
          shouldRefresh = true
        end
      end
    end
    shouldRefresh && rebuildLocalizations(project)
    sleep(5)
  end
end
