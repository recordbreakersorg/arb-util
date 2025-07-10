#!/usr/bin/fish

alias juliaexe "julia +nightly"

function trimpile
    mkdir bin
    echo "Compiling src/main.jl with juliac with safe triming"
    juliaexe +nightly --project=. juliac/juliac.jl --experimental --output-exe bin/arb-util --trim=safe src/main.jl
end

function run
    set mainpath "$(path dirname (status --current-filename))/src/main.jl"
    juliaexe $mainpath $mainpath
end

if test "$argv[1]" = trimpile
    trimpile
else if test "$argv[1]" = run
    run
else
    echo "Invalid command, use `./build.fish trimpile`"
end
