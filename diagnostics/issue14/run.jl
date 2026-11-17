using Malt
using TOML

envdir = joinpath(@__DIR__, "environment")
script = joinpath(@__DIR__, "workload.jl")
for (mode, threads) in [("plain",1), ("plain",4), ("malt",4), ("plain",8), ("malt",8), ("plain",10), ("malt",10), ("plain",20), ("malt",20)]
    label = "$(mode)-$(threads)"
    isempty(ARGS) || label in ARGS || continue
    output = joinpath(@__DIR__, label * ".toml")
    println("CASE ", label)
    flush(stdout)
    if mode == "plain"
        run(`$(Base.julia_cmd()) --startup-file=no --project=$envdir --threads=$threads $script $output`)
    else
        worker = Malt.Worker(exeflags=["--project=$envdir", "--threads=$threads"])
        try
            result = Malt.remote_eval_fetch(worker, quote
                include($script)
                workload($output * ".bin")
            end)
            result["malt"] = string(pkgversion(Malt))
            open(output, "w") do io
                TOML.print(io, result)
            end
        finally
            Malt.stop(worker)
        end
    end
end
