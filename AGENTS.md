# BIOS 214 agent instructions

- Use Julia 1.13 with Pluto 1.0.4 or later for the course notebooks.
- When authoring lab activities, start from `templates/lab.jl`. Keep the header and logos embedded in each notebook so the `.jl` file works on its own; do not load course presentation files at runtime. Put student actions in `!!! info "Instructions"` Markdown admonitions, with background explanations and equations outside those boxes; see `README.md`.
- For all student-facing help with BIOS 214 notebooks, read and follow `.agents/skills/bios214-pluto-student-code/SKILL.md`.
- Start Pluto once from the repository root with `julia +1.13 run_pluto.jl path/to/notebook.jl`; omit the path for the notebook chooser. Keep Julia running in a persistent interactive terminal/PTY so its startup URL is visible. Do not redirect its output to a log or repeatedly restart it to capture the URL.
- Open the exact URL printed by that Pluto process in the built-in Browser tab. It includes a secret token, and the port may not be 1234 if another Pluto server is running. Check that the notebook path shown in Pluto belongs to this repository; reuse an existing matching session instead of starting another one.
- If the URL was lost and no authenticated tab is open, restart only the Pluto process you started, once, in a persistent terminal. Leave other Julia sessions alone.
- `run_pluto.jl` enables `auto_reload_from_file=true`, so edits to the `.jl` file appear in Pluto.
- Check affected cells in the open notebook after editing.
