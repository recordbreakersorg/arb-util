#!/usr/bin/fish

alias juliaexe "julia +nightly"

function projectdir
    path dirname (status --current-filename)
end

function trimpile
    mkdir bin
    echo "Compiling src/main.jl with juliac with safe triming"
    juliaexe --project=(projectdir) juliac/juliac.jl --experimental --output-exe bin/arb-util --trim=safe src/main.jl
end

function run
    set mainpath "$(projectdir)/src/main.jl"
    juliaexe --project=(projectdir) $mainpath $mainpath
end

if test "$argv[1]" = trimpile
    trimpile
else if test "$argv[1]" = run
    run
else
    echo "Invalid command, use `./build.fish trimpile`"
end
