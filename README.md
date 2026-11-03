# BIOS 214

> [!WARNING]
> **Work in progress:** These course materials are under active development and may be incomplete or change.

Course notebooks and agent instructions. `labs/activity0.jl` is an unsolved example for a TA to try in the student role.

Clone the repository:

```sh
git clone https://github.com/cncastillo/bios-214.git
cd bios-214
```

Open the cloned repository as a project in Codex or Claude Code. In the project terminal, start Activity 0 with Julia 1.13:

```sh
julia +1.13 run_pluto.jl labs/activity0.jl
```

Keep that terminal running. In Codex, paste the full URL printed by Pluto into the built-in Browser tab; it opens Activity 0 directly. The launcher enables file reload, so edits to the `.jl` file appear in Pluto. Omit the notebook path to open Pluto's notebook chooser. If Pluto 1.0.4 or newer is not installed for Julia 1.13, run `julia +1.13 -e 'import Pkg; Pkg.add(Pkg.PackageSpec(name="Pluto", version="1.0.4"))'` once. If you do not use juliaup, replace `julia +1.13` with your Julia 1.13 executable.

In Activity 0, ask the agent to implement the Basel approximation, then predict and check how changing the number of terms affects the result. The repository instructions point both agents to the same student-coding skill.

## Authoring lab activities

Copy [templates/lab.jl](templates/lab.jl) into `labs/` and edit its activity title and tasks. The header and both logo variants are embedded directly in the notebook, so the `.jl` file can be shared on its own. All CSS is embedded in the header cell; copy that cell to update branding or admonition styles in existing labs.

The unmodified stacked color and white logos come from the Stanford School of Medicine [official logo downloads](https://med.stanford.edu/content/sm/identity/how-we-look/logo.html). Stanford names and logos remain the property of Stanford University; the repository license does not apply to these marks.

Put student actions in native Markdown admonitions, keeping background explanations and equations outside the box:

```julia
md"""
!!! info "Instructions"
    Move the sliders and watch the tree redraw automatically.
"""
```
