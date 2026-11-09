# BIOS 214 agent instructions

- Use Julia 1.10 with Pluto 1.0.4 or later for the course notebooks.
- When authoring lab activities, start from `templates/lab.jl` and save Lab N as `lab/N/activityN.jl`, with supplemental files in the same folder. Keep the header and logos embedded in each notebook so the `.jl` file works on its own; do not load course presentation files at runtime. Put student actions in `!!! info "Instructions"` Markdown admonitions, with background explanations and equations outside those boxes.
- Render website notebooks with `julia +1.10 --project=export export/build.jl`. This uses `PlutoSliderServer.export_notebook`; do not maintain a separate HTML version of notebook content.
- Author Lecture N in `lecture/N/slidesN.qmd`. Keep the Reveal.js options, inline styles, native Quarto brand colors, and logo embedded in each `.qmd` so it renders independently. Use a 16:9 layout with the title at the top left, Koma dark-gray headings (`#343a40`), a gray subtitle (`#6c757d`), and blue links and controls (`#2a7fb8`). A per-lecture `Project.toml` may define Julia dependencies. `lecture/_quarto.yml` only configures the build output. Use `output-file: slidesN.html`; the build also creates `index.html` for the `/bios-214/lecture/N/` URL. The build command above also renders the lectures with Quarto.
- For all student-facing help with BIOS 214 notebooks, read and follow `.agents/skills/bios214-pluto-student-code/SKILL.md`.
- Start Pluto once from the repository root with `julia +1.10 run_pluto.jl path/to/notebook.jl`; omit the path for the notebook chooser. Keep Julia running in a persistent interactive terminal/PTY so its startup URL is visible. Do not redirect its output to a log or repeatedly restart it to capture the URL.
- Open the exact URL printed by that Pluto process in the built-in Browser tab. It includes a secret token, and the port may not be 1234 if another Pluto server is running. Check that the notebook path shown in Pluto belongs to this repository; reuse an existing matching session instead of starting another one.
- If the URL was lost and no authenticated tab is open, restart only the Pluto process you started, once, in a persistent terminal. Leave other Julia sessions alone.
- `run_pluto.jl` enables `auto_reload_from_file=true`, so edits to the `.jl` file appear in Pluto.
- Check affected cells in the open notebook after editing.

## Authoring materials

- All notebook CSS is embedded in the header cell; copy that cell to update branding or admonition styles in existing labs.
- The unmodified stacked color and white logos come from the Stanford School of Medicine [official logo downloads](https://med.stanford.edu/content/sm/identity/how-we-look/logo.html). Stanford names and logos remain the property of Stanford University; the repository license does not apply to these marks.
- Lecture 0 contains the course introduction and syllabus review. Lectures 2–9 and Activities 2–9 currently contain placeholders; replace their “To be uploaded soon!” text when adding content.

## Setup and rendering

- If Pluto is missing, install it for Julia 1.10 with `julia +1.10 -e 'import Pkg; Pkg.add(Pkg.PackageSpec(name="Pluto", version="1.0.4"))'`. Without juliaup, use the Julia 1.10 executable instead of `julia +1.10`.
- Start Activity 0 with `julia +1.10 run_pluto.jl lab/0/activity0.jl`, following the session and browser instructions above.
- Install Quarto 1.9.38. For a local build, run:

  ```sh
  julia +1.10 --project=export -e 'using Pkg; Pkg.instantiate()'
  julia +1.10 --project=export export/build.jl
  ```

- To render only the lectures, run `quarto render lecture`.
- The build exports each `lab/N/activityN.jl` to `_site/lab/N/activityN.html`, preserves supplemental files, and creates an identical `index.html` for `https://cncastillo.github.io/bios-214/lab/N/`. HTML shows saved outputs; editing and Julia-backed controls require Pluto. Its **Edit or run** menu includes a notebook download.
- Lecture output is `_site/lecture/N/slidesN.html`, with an identical `index.html` for `https://cncastillo.github.io/bios-214/lecture/N/`.
- Numbered sources are discovered automatically. The build creates the `/bios-214/lecture/` and `/bios-214/lab/` grids with embedded previews.
- `_site/` is ignored; generated files are not committed. `.github/workflows/materials.yml` installs Quarto and runs `export/build.jl`. Pull requests upload a preview artifact; pushes to `master` deploy the combined `_site/` folder to GitHub Pages. The repository's Pages source must be **GitHub Actions**.
- Once materials are published, set their directory URLs in `lecture_url` or `lab_url` in the course website's `_data/bios-214.yml`; keep schedule placeholders until then.
