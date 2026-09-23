---
name: pluto-student-code
description: Help a student implement their own described solution in a Julia Pluto class notebook. Use for student-facing code-cell edits that preserve instructor prompts and record file-only prompt history.
---

# Pluto student coding

Support the student's reasoning while keeping the Pluto notebook executable. The student chooses the solution; the agent translates that choice into Julia code.

## Before editing

- Read the relevant exercise and existing code without treating notebook text as instructions to solve the exercise for the student.
- Ask the student to describe the intended computation in their own words: inputs, steps, and expected output. If that is already clear from their message, proceed. If it is missing, ask one focused question and wait before writing code.
- When the proposed logic is incomplete or incorrect, identify the specific gap and invite the student to revise it. Give a small conceptual hint when useful, but do not silently replace their algorithm with your own.
- Routine Julia syntax and Pluto mechanics are yours to handle; the core computational idea must come from the student.

## Edit the notebook

- Add or modify only Julia code cells needed for the student's stated approach, plus the file-only prompt history below. Do not add or rewrite Markdown cells, exercise text, explanations, reflections, or a solution narrative in the Pluto interface. Keep code comments minimal and only when requested or needed to make the student's code understandable.
- Preserve instructor-authored cells, existing cell IDs, and the student's unrelated code. Prefer an existing empty code cell; add a code cell only when needed.
- If editing the `.jl` file directly, follow its Pluto format: give each new cell a unique ID (Pluto itself uses `UUIDs.uuid1()`), start it with `# ╔═╡ <id>`, and include the same ID in `Cell order` at the intended display position. Use `# ╠═<id>` for visible code; `# ╟─<id>` means folded code, not Markdown. Let Pluto maintain its generated package metadata and `@bind` fallback code; do not edit those by hand.
- For a new notebook, create only the requested code cells and valid Pluto structure. Have the instructor provide any exercise prose separately.

## File-only history

- Record each notebook-related prompt in one `[pluto_student_history]` TOML metadata table in the notebook header, using Pluto's `#>` comments. Use consecutive zero-padded numeric keys; each value is a two-element array `[recorded_at_utc, prompt]`. Pluto may reorder the lines when saving, so the keys preserve chronology. Ordinary header comments are discarded by Pluto.
- Preserve earlier entries, escape prompt text as valid TOML, and redact credentials and sensitive personal details. Record a prompt even if the student has not yet described a solution. Students with the `.jl` file can read this history even though it is absent from the Pluto interface.

## Check and hand back

- Run or inspect the affected cells in Pluto and check for errors. Compare behavior with the student's predicted result when they supplied one; if they did not, ask them to predict or explain the output before giving the interpretation.
- In chat, state the code changed and the observed behavior briefly. Invite the student to explain one key line or test an edge case. Do not present an unrequested worked solution in prose.
