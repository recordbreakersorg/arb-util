# Script to run in the process that generates juliac's object file output

# Run the verifier in the current world (before modifications), so that error
# messages and types print in their usual way.
Core.Compiler._verify_trim_world_age[] = Base.get_world_counter()

# Initialize some things not usually initialized when output is requested
Sys.__init__()
Base.init_depot_path()
Base.init_load_path()
Base.init_active_project()
task = current_task()
task.rngState0 = 0x5156087469e170ab
task.rngState1 = 0x7431eaead385992c
task.rngState2 = 0x503e1d32781c2608
task.rngState3 = 0x3a77f7189200c20b
task.rngState4 = 0x5502376d099035ae
uuid_tuple = (UInt64(0), UInt64(0))
ccall(:jl_set_module_uuid, Cvoid, (Any, NTuple{2,UInt64}), Base.__toplevel__, uuid_tuple)
if Base.get_bool_env("JULIA_USE_FLISP_PARSER", false) === false
  Base.JuliaSyntax.enable_in_core!()
end

# Patch methods in Core and Base

@eval Core begin
  DomainError(@nospecialize(val), @nospecialize(msg::AbstractString)) = (@noinline; $(Expr(:new, :DomainError, :val, :msg)))
end

(f::Base.RedirectStdStream)(io::Core.CoreSTDOUT) = Base._redirect_io_global(io, f.unix_fd)

@eval Base begin
  depwarn(msg, funcsym; force::Bool=false) = nothing
  _assert_tostring(msg) = ""
  reinit_stdio() = nothing
  JuliaSyntax.enable_in_core!() = nothing
  init_active_project() = ACTIVE_PROJECT[] = nothing
  set_active_project(projfile::Union{AbstractString,Nothing}) = ACTIVE_PROJECT[] = projfile
  disable_library_threading() = nothing
  start_profile_listener() = nothing
  invokelatest_trimmed(f, args...; kwargs...) = f(args...; kwargs...)
  const invokelatest = invokelatest_trimmed
  function sprint(f::F, args::Vararg{Any,N}; context=nothing, sizehint::Integer=0) where {F<:Function,N}
    s = IOBuffer(sizehint=sizehint)
    if context isa Tuple
      f(IOContext(s, context...), args...)
    elseif context !== nothing
      f(IOContext(s, context), args...)
    else
      f(s, args...)
    end
    String(_unsafe_take!(s))
  end
  function show_typeish(io::IO, @nospecialize(T))
    if T isa Type
      show(io, T)
    elseif T isa TypeVar
      print(io, (T::TypeVar).name)
    else
      print(io, "?")
    end
  end
  function show(io::IO, T::Type)
    if T isa DataType
      print(io, T.name.name)
      if T !== T.name.wrapper && length(T.parameters) > 0
        print(io, "{")
        first = true
        for p in T.parameters
          if !first
            print(io, ", ")
          end
          first = false
          if p isa Int
            show(io, p)
          elseif p isa Type
            show(io, p)
          elseif p isa Symbol
            print(io, ":")
            print(io, p)
          elseif p isa TypeVar
            print(io, p.name)
          else
            print(io, "?")
          end
        end
        print(io, "}")
      end
    elseif T isa Union
      print(io, "Union{")
      show_typeish(io, T.a)
      print(io, ", ")
      show_typeish(io, T.b)
      print(io, "}")
    elseif T isa UnionAll
      print(io, T.body::Type)
      print(io, " where ")
      print(io, T.var.name)
    end
  end
  show_type_name(io::IO, tn::Core.TypeName) = print(io, tn.name)

  mapreduce(f::F, op::F2, A::AbstractArrayOrBroadcasted; dims=:, init=_InitialValue()) where {F,F2} =
    _mapreduce_dim(f, op, init, A, dims)
  mapreduce(f::F, op::F2, A::AbstractArrayOrBroadcasted...; kw...) where {F,F2} =
    reduce(op, map(f, A...); kw...)

  _mapreduce_dim(f::F, op::F2, nt, A::AbstractArrayOrBroadcasted, ::Colon) where {F,F2} =
    mapfoldl_impl(f, op, nt, A)

  _mapreduce_dim(f::F, op::F2, ::_InitialValue, A::AbstractArrayOrBroadcasted, ::Colon) where {F,F2} =
    _mapreduce(f, op, IndexStyle(A), A)

  _mapreduce_dim(f::F, op::F2, nt, A::AbstractArrayOrBroadcasted, dims) where {F,F2} =
    mapreducedim!(f, op, reducedim_initarray(A, dims, nt), A)

  _mapreduce_dim(f::F, op::F2, ::_InitialValue, A::AbstractArrayOrBroadcasted, dims) where {F,F2} =
    mapreducedim!(f, op, reducedim_init(f, op, A, dims), A)

  mapreduce_empty_iter(f::F, op::F2, itr, ItrEltype) where {F,F2} =
    reduce_empty_iter(MappingRF(f, op), itr, ItrEltype)
  mapreduce_first(f::F, op::F2, x) where {F,F2} = reduce_first(op, f(x))

  _mapreduce(f::F, op::F2, A::AbstractArrayOrBroadcasted) where {F,F2} = _mapreduce(f, op, IndexStyle(A), A)
  mapreduce_empty(::typeof(identity), op::F, T) where {F} = reduce_empty(op, T)
  mapreduce_empty(::typeof(abs), op::F, T) where {F} = abs(reduce_empty(op, T))
  mapreduce_empty(::typeof(abs2), op::F, T) where {F} = abs2(reduce_empty(op, T))
end
@eval Base.Sys begin
  __init_build() = nothing
end
@eval Base.GMP begin
  function __init__()
    try
      ccall((:__gmp_set_memory_functions, libgmp), Cvoid,
        (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
        cglobal(:jl_gc_counted_malloc),
        cglobal(:jl_gc_counted_realloc_with_old_size),
        cglobal(:jl_gc_counted_free_with_size))
      ZERO.alloc, ZERO.size, ZERO.d = 0, 0, C_NULL
      ONE.alloc, ONE.size, ONE.d = 1, 1, pointer(_ONE)
    catch ex
      Base.showerror_nostdio(ex, "WARNING: Error during initialization of module GMP")
    end
    # This only works with a patched version of GMP, ignore otherwise
    try
      ccall((:__gmp_set_alloc_overflow_function, libgmp), Cvoid,
        (Ptr{Cvoid},),
        cglobal(:jl_throw_out_of_memory_error))
      ALLOC_OVERFLOW_FUNCTION[] = true
    catch ex
      # ErrorException("ccall: could not find function...")
      if typeof(ex) != ErrorException
        rethrow()
      end
    end
  end
end
@eval Base.Sort begin
  issorted(itr;
    lt::T=isless, by::F=identity, rev::Union{Bool,Nothing}=nothing, order::Ordering=Forward) where {T,F} =
    issorted(itr, ord(lt, by, rev, order))
end
@eval Base.TOML begin
  function try_return_datetime(p, year, month, day, h, m, s, ms)
    return DateTime(year, month, day, h, m, s, ms)
  end
  function try_return_date(p, year, month, day)
    return Date(year, month, day)
  end
  function parse_local_time(l::Parser)
    h = @try parse_int(l, false)
    h in 0:23 || return ParserError(ErrParsingDateTime)
    _, m, s, ms = @try _parse_local_time(l, true)
    # TODO: Could potentially parse greater accuracy for the
    # fractional seconds here.
    return try_return_time(l, h, m, s, ms)
  end
  function try_return_time(p, h, m, s, ms)
    return Time(h, m, s, ms)
  end
end

# Load user code

import Base.Experimental.entrypoint

# for use as C main if needed
function _main(argc::Cint, argv::Ptr{Ptr{Cchar}})::Cint
  args = ccall(:jl_set_ARGS, Any, (Cint, Ptr{Ptr{Cchar}}), argc, argv)::Vector{String}
  return Main.main(args)
end

let mod = Base.include(Main, ARGS[1])
  Core.@latestworld
  if ARGS[2] == "--output-exe"
    have_cmain = false
    if isdefined(Main, :main)
      for m in methods(Main.main)
        if isdefined(m, :ccallable)
          # TODO: possibly check signature and return type
          have_cmain = true
          break
        end
      end
    end
    if !have_cmain
      if Base.should_use_main_entrypoint()
        if hasmethod(Main.main, Tuple{Vector{String}})
          entrypoint(_main, (Cint, Ptr{Ptr{Cchar}}))
          Base._ccallable("main", Cint, Tuple{typeof(_main),Cint,Ptr{Ptr{Cchar}}})
        else
          error("`@main` must accept a `Vector{String}` argument.")
        end
      else
        error("To generate an executable a `@main` function must be defined.")
      end
    end
  end
  #entrypoint(join, (Base.GenericIOBuffer{Memory{UInt8}}, Array{Base.SubString{String}, 1}, String))
  #entrypoint(join, (Base.GenericIOBuffer{Memory{UInt8}}, Array{String, 1}, Char))
  entrypoint(Base.task_done_hook, (Task,))
  entrypoint(Base.wait, ())
  entrypoint(Base.wait_forever, ())
  entrypoint(Base.trypoptask, (Base.StickyWorkqueue,))
  entrypoint(Base.checktaskempty, ())
  if ARGS[3] == "true"
    ccall(:jl_add_ccallable_entrypoints, Cvoid, ())
  end
end

# Additional method patches depending on whether user code loads certain stdlibs
let
  find_loaded_root_module(key::Base.PkgId) = Base.maybe_root_module(key)

  SparseArrays = find_loaded_root_module(Base.PkgId(
    Base.UUID("2f01184e-e22b-5df5-ae63-d93ebab69eaf"), "SparseArrays"))
  if SparseArrays !== nothing
    @eval SparseArrays.CHOLMOD begin
      function __init__()
        ccall((:SuiteSparse_config_malloc_func_set, :libsuitesparseconfig),
          Cvoid, (Ptr{Cvoid},), cglobal(:jl_malloc, Ptr{Cvoid}))
        ccall((:SuiteSparse_config_calloc_func_set, :libsuitesparseconfig),
          Cvoid, (Ptr{Cvoid},), cglobal(:jl_calloc, Ptr{Cvoid}))
        ccall((:SuiteSparse_config_realloc_func_set, :libsuitesparseconfig),
          Cvoid, (Ptr{Cvoid},), cglobal(:jl_realloc, Ptr{Cvoid}))
        ccall((:SuiteSparse_config_free_func_set, :libsuitesparseconfig),
          Cvoid, (Ptr{Cvoid},), cglobal(:jl_free, Ptr{Cvoid}))
      end
    end
  end

  Artifacts = find_loaded_root_module(Base.PkgId(
    Base.UUID("56f22d72-fd6d-98f1-02f0-08ddc0907c33"), "Artifacts"))
  if Artifacts !== nothing
    @eval Artifacts begin
      function _artifact_str(
        __module__,
        artifacts_toml,
        name,
        path_tail,
        artifact_dict,
        hash,
        platform,
        _::Val{LazyArtifacts}
      ) where LazyArtifacts
        # If the artifact exists, we're in the happy path and we can immediately
        # return the path to the artifact:
        dirs = artifacts_dirs(bytes2hex(hash.bytes))
        for dir in dirs
          if isdir(dir)
            return jointail(dir, path_tail)
          end
        end
        error("Artifact not found")
      end
    end
  end

  Pkg = find_loaded_root_module(Base.PkgId(
    Base.UUID("44cfe95a-1eb2-52ea-b672-e2afdf69b78f"), "Pkg"))
  if Pkg !== nothing
    @eval Pkg begin
      __init__() = rand() #TODO, methods that do nothing don't get codegened
    end
  end

  StyledStrings = find_loaded_root_module(Base.PkgId(
    Base.UUID("f489334b-da3d-4c2e-b8f0-e476e12c162b"), "StyledStrings"))
  if StyledStrings !== nothing
    @eval StyledStrings begin
      __init__() = rand()
    end
  end

  Markdown = find_loaded_root_module(Base.PkgId(
    Base.UUID("d6f4376e-aef5-505a-96c1-9c027394607a"), "Markdown"))
  if Markdown !== nothing
    @eval Markdown begin
      __init__() = rand()
    end
  end

  JuliaSyntaxHighlighting = find_loaded_root_module(Base.PkgId(
    Base.UUID("ac6e5ff7-fb65-4e79-a425-ec3bc9c03011"), "JuliaSyntaxHighlighting"))
  if JuliaSyntaxHighlighting !== nothing
    @eval JuliaSyntaxHighlighting begin
      __init__() = rand()
    end
  end
end

empty!(Core.ARGS)
empty!(Base.ARGS)
empty!(LOAD_PATH)
empty!(DEPOT_PATH)
empty!(Base.TOML_CACHE.d)
Base.TOML.reinit!(Base.TOML_CACHE.p, "")
Base.ACTIVE_PROJECT[] = nothing
@eval Base begin
  PROGRAM_FILE = ""
end
@eval Sys begin
  BINDIR = ""
  STDLIB = ""
end
