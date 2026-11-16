source = replace(read(joinpath(@__DIR__, "activity2-source.jl"), String), "\r\n" => "\n")
envdir = joinpath(@__DIR__, "environment")
mkpath(envdir)
for (name, marker) in [("Project", "PROJECT"), ("Manifest", "MANIFEST")]
    contents = match(Regex("(?s)PLUTO_" * marker * "_TOML_CONTENTS = \"\"\"(.*?)\"\"\""), source).captures[1]
    write(joinpath(envdir, name * ".toml"), contents)
end
id = "2cd7102e-dd92-11f1-8cb3-895d35658f26"
cell = match(Regex("(?ms)^# ╔═╡ " * id * "\\n(.*?)(?=^# ╔═╡ |\\z)"), source).captures[1]
write(joinpath(@__DIR__, id * ".jl"), cell)
println("Extracted the published Activity 2 environment")
