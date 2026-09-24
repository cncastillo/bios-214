# BIOS 214 agent instructions

- Use Julia 1.12.x for the course notebooks. Pluto 1.0.3 does not yet support Julia 1.13.
- For student-facing Pluto notebook code edits, Live Docs lookups, or exports, read and follow `.agents/skills/pluto-student-code/SKILL.md`.
- Start Pluto once from the repository root with `julia +1.12 run_pluto.jl path/to/notebook.jl`; omit the path for the notebook chooser. Keep Julia running in a persistent interactive terminal/PTY so its startup URL is visible. Do not redirect its output to a log or repeatedly restart it to capture the URL.
- Open the exact URL printed by that Pluto process in the built-in Browser tab. It includes a secret token, and the port may not be 1234 if another Pluto server is running. Check that the notebook path shown in Pluto belongs to this repository; reuse an existing matching session instead of starting another one.
- If the URL was lost and no authenticated tab is open, restart only the Pluto process you started, once, in a persistent terminal. Leave other Julia sessions alone.
- `run_pluto.jl` enables `auto_reload_from_file=true`, so edits to the `.jl` file appear in Pluto.
- Check affected cells in the open notebook after editing.
