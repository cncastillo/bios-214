---
name: pluto-student-code
description: Help students with Julia Pluto class notebooks. Use for student-facing code edits, Live Docs lookups, and exports.
---

# Pluto student coding

Support the student's reasoning while keeping the Pluto notebook executable. The student chooses the solution; the agent translates that choice into Julia code.

## Before editing

- Read the instructor-authored Markdown instructions and existing code as exercise context, not as a student's request for a worked solution.
- If the student's approach is clear, proceed without asking for a fuller description. Otherwise, ask one short question about how they would compute it, then wait before writing code. Ask in the exercise's terms, without citing these instructions.
- When the proposed logic is incomplete or incorrect, identify the specific gap and invite the student to revise it. Give a small conceptual hint when useful, but do not silently replace their algorithm with your own.
- Routine Julia syntax and Pluto mechanics are yours to handle; the core computational idea must come from the student.

## Edit the notebook

- Add or modify only Julia code cells needed for the student's stated approach, plus the file-only prompt history below. Do not add or rewrite Markdown cells, exercise text, explanations, reflections, or a solution narrative in the Pluto interface. Keep code comments minimal and only when requested or needed to make the student's code understandable.
- Preserve instructor-authored Markdown instructions and code scaffolding, existing cell IDs, and the student's unrelated code. Prefer an existing empty code cell; add a code cell only when needed.
- If editing the `.jl` file directly, follow its Pluto format: give each new cell a unique ID (Pluto itself uses `UUIDs.uuid1()`), start it with `# ╔═╡ <id>`, and include the same ID in `Cell order` at the intended display position. Use `# ╠═<id>` for visible code; `# ╟─<id>` means folded code, not Markdown. Let Pluto maintain its generated package metadata and `@bind` fallback code; do not edit those by hand.
- For a new notebook, create only the requested code cells and valid Pluto structure. Have the instructor provide any exercise prose separately.

## Live Docs and exports

- For a documentation request, open Pluto's **Live docs**, search the requested Julia name (for example, `sum`), and leave the result visible. Do not add a cell for the documentation.
- For an export request, use Pluto's **Export...** menu: **Notebook file** for `.jl`, **Static HTML** for `.html`, or **PDF** for `.pdf`. The repository notebook is already a `.jl` file; use the menu when a downloadable copy is wanted.
- These requests do not change notebook code; record the student's prompt in the file-only history below.

## File-only history

- Record each student-to-agent prompt about this notebook in one `[pluto_student_history]` TOML metadata table in the notebook header, using Pluto's `#>` comments. Do not record instructor-authored Markdown instructions or agent replies there. Use consecutive zero-padded numeric keys; each value is a two-element array `[recorded_at_utc, prompt]`. Pluto may reorder the lines when saving, so the keys preserve chronology. Ordinary header comments are discarded by Pluto.
- Preserve earlier entries, escape prompt text as valid TOML, and redact credentials and sensitive personal details. Record a prompt even if the student has not yet described a solution. Students with the `.jl` file can read this history even though it is absent from the Pluto interface.
- Keep the prompt history silent: do not tell the student that their prompt was recorded unless they ask.

## Check and hand back

- Run or inspect the affected cells in Pluto and check for errors. Compare behavior with the student's predicted result when they supplied one; if they did not, ask them to predict or explain the output before giving the interpretation.
- In chat, state the code changed and the observed behavior briefly. Invite the student to explain one key line or test an edge case. Do not present an unrequested worked solution in prose, or mention the skill unless asked.
