using Pluto

session = Pluto.ServerSession(; options=Pluto.Configuration.from_flat_kwargs(threads=Threads.nthreads()))
notebook = Pluto.SessionActions.open(session, joinpath(@__DIR__, "notebook.jl"); run_async=false)
try
    for cell in notebook.cells
        println(cell.cell_id, ": ", cell.output.body)
        @assert !cell.errored
        @assert !cell.running && !cell.queued
    end
    println("Pluto's isolated notebook environment passed")
finally
    Pluto.SessionActions.shutdown(session, notebook)
end
