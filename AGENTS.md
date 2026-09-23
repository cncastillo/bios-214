# BIOS 214 agent instructions

- Use Julia 1.12.x for the course notebooks. Pluto 1.0.3 does not yet support Julia 1.13.
- For student-facing edits to a Pluto notebook, read and follow `.agents/skills/pluto-student-code/SKILL.md` before changing the file.
- Run `julia run_pluto.jl path/to/notebook.jl` from the repository root with Julia 1.12. The script starts Pluto with `auto_reload_from_file=true` and prints its local URL; omit the path to open Pluto's notebook chooser. In Codex desktop, open the printed URL in the built-in Browser tab. Edits made by an agent or directly in its `.jl` file then appear in Pluto.
- Check affected cells in the open notebook after editing.
