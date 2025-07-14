#!/usr/bin/fish

alias juliaexe "julia +nightly"

function projectdir
    path dirname (status --current-filename)
end

function trimpile
    mkdir bin
    echo "[manage.fish] Compiling src/main.jl with juliac with safe triming"
    juliaexe --project=(projectdir) juliac/juliac.jl --experimental --output-exe bin/arb-util --trim=safe src/main.jl
end

function compile
    mkdir bin
    echo "[manage.fish] Compiling src/main.jl with juliac with safe triming"
    juliaexe --project=(projectdir) juliac/juliac.jl --experimental --output-exe bin/arb-util src/main.jl
end

function run
    set mainpath "$(projectdir)/src/main.jl"
    set exepath ./bin/arb-util
    if test -e $exepath
        echo "[manage.fish] Running binary at $exepath"
        $exepath $mainpath
    else
        echo "[manage.fish] Running using julia"
        juliaexe --project=(projectdir) $mainpath $mainpath
    end
end

if test "$argv[1]" = trimpile
    trimpile
else if test "$argv[1]" = compile
    compile
else if test "$argv[1]" = run
    run
else
    echo "Invalid command, use `./manage.fish trimpile|compile|run`"
end
