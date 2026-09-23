# BIOS 214

Course notebooks and agent instructions. `labs/activity0.jl` is an unsolved example for a TA to try in the student role.

After accepting the repository invitation, clone it:

```sh
git clone https://github.com/cncastillo/bios-214.git
cd bios-214
```

Open the cloned repository as a project in Codex or Claude Code. In the project terminal, start Activity 0 with Julia 1.12:

```sh
julia +1.12 run_pluto.jl labs/activity0.jl
```

Keep that terminal running. In Codex, paste the full URL printed by Pluto into the built-in Browser tab; it opens Activity 0 directly. The launcher enables file reload, so edits to the `.jl` file appear in Pluto. Omit the notebook path to open Pluto's notebook chooser. If Pluto is not installed for Julia 1.12, run `julia +1.12 -e 'import Pkg; Pkg.add("Pluto")'` once. If you do not use juliaup, replace `julia +1.12` with your Julia 1.12 executable.

In Activity 0, describe your intended computation to the agent and ask it to implement that code in the notebook. The repository instructions point both agents to the same student-coding skill.
