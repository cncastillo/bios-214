using PlutoSliderServer

root = dirname(@__DIR__)
site_output = joinpath(root, "_site")
rm(site_output; recursive=true, force=true)
mkpath(site_output)
lab_output = joinpath(site_output, "lab")
cp(joinpath(root, "lab"), lab_output)

for lab in readdir(lab_output; join=true)
    notebook = joinpath(lab, "activity$(basename(lab)).jl")
    isfile(notebook) || continue
    PlutoSliderServer.export_notebook(notebook; Export_create_index=false)
    cp(splitext(notebook)[1] * ".html", joinpath(lab, "index.html"))
end

for lecture in readdir(joinpath(root, "lecture"); join=true)
    isfile(joinpath(lecture, "Project.toml")) || continue
    run(`$(Base.julia_cmd()) --project=$lecture -e "using Pkg; Pkg.instantiate()"`)
end

run(addenv(`quarto render $(joinpath(root, "lecture"))`,
    "QUARTO_JULIA" => joinpath(Sys.BINDIR, Base.julia_exename())))

for lecture in readdir(joinpath(site_output, "lecture"); join=true)
    html = joinpath(lecture, "slides$(basename(lecture)).html")
    isfile(html) || continue
    cp(html, joinpath(lecture, "index.html"))
end

function write_material_index(kind, title, label, prefix, extension)
    folders = filter(readdir(joinpath(root, kind); join=true)) do folder
        isfile(joinpath(folder, "$(prefix)$(basename(folder)).$(extension)"))
    end
    sort!(folders; by=folder -> parse(Int, basename(folder)))
    cards = map(folders) do folder
        number = basename(folder)
        source = read(joinpath(folder, "$(prefix)$number.$extension"), String)
        name = if kind == "lecture"
            html = read(joinpath(site_output, kind, number, "index.html"), String)
            replace(match(r"<title>(.*?)</title>"s, html)[1], r"^Lecture \d+\s+" => "")
        else
            replace(match(r"(?m)^# Activity \d+: (.+)$", source)[1], "&" => "&amp;", "<" => "&lt;")
        end
        """
        <article class="material">
          <div class="preview">
            <iframe src="$number/" title="$label $number preview" loading="lazy" tabindex="-1" aria-hidden="true"></iframe>
          </div>
          <a class="material-link" href="$number/" aria-label="$label $number: $(replace(name, '\"' => "&quot;"))"></a>
        </article>
        """
    end
    other, other_title = kind == "lecture" ? ("lab", "Lab activities") : ("lecture", "Lectures")
    write(joinpath(site_output, kind, "index.html"), """
    <!doctype html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>BIOS 214 · $title</title>
      <style>
        body { max-width: 76rem; margin: 2.5rem auto; padding: 0 1.25rem;
               font-family: system-ui, sans-serif; line-height: 1.5; color: #343a40; }
        a { color: #2a7fb8; }
        h1 { margin: 1.5rem 0; }
        .materials { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 1.5rem; }
        .material { position: relative; overflow: hidden; border: 1px solid #d8dde1; border-radius: 6px; }
        .material:hover, .material:focus-within { border-color: #2a7fb8; }
        .preview { position: relative; aspect-ratio: 16 / 9; overflow: hidden;
                   background: #fff; color-scheme: only light; }
        .preview iframe { position: absolute; width: 300%; height: 300%; border: 0;
                          transform: scale(0.333333); transform-origin: top left; pointer-events: none; }
        .material-link { position: absolute; inset: 0; }
        @media (max-width: 640px) { .materials { grid-template-columns: 1fr; } }
      </style>
    </head>
    <body>
      <nav aria-label="Course materials">
        <a href="/teaching/bios-214/">Course website</a> ·
        <a href="../$other/">$other_title</a>
      </nav>
      <main>
        <h1>BIOS 214 · $title</h1>
        <div class="materials">$(join(cards, "\n"))</div>
      </main>
    </body>
    </html>
    """)
end

write_material_index("lecture", "Lectures", "Lecture", "slides", "qmd")
write_material_index("lab", "Lab activities", "Activity", "activity", "jl")
