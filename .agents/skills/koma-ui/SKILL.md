---
name: koma-ui
description: Open KomaMRI's UI in the agent app's in-app browser and control it from Julia. Use for loading Pulseq sequences and phantoms, inspecting plots, simulating, reconstructing, and checking UI operation status.
---

# KomaMRI browser UI

Use KomaMRI's public Julia UI API to control the same window the user sees. These instructions target the API available in KomaMRI 0.15; check the installed version and docstrings when behavior differs.

## Open and connect

- Use the relevant Julia project and a persistent threaded REPL. Reuse an existing `KomaWindow` and its server rather than launching another UI for each request.
- If no matching UI exists, run `using KomaMRI` and `w = KomaUI(; browser=true, return_window=true)`. KomaUI tries its default port and selects another if it is occupied. Keep the REPL running and retain `w` for subsequent commands. Avoid `port=0`: the Bonito version compatible with Julia 1.10 does not report the assigned port correctly.
- Open the exact URL printed by KomaUI, or returned by `ui_status(w).url`, in the agent app's in-app browser (for example, Codex or Claude). Do not guess port 9384 or reuse another server's URL. Reuse an existing matching browser tab. Keep the browser visible when the user asks to watch the interaction; if the app has no in-app browser, provide the actual URL and explain that limitation.
- Check `ui_status(w).connected` and the visible page before proceeding. If a long initial compilation disconnected the browser, reload the existing tab after Julia is responsive; do not restart a healthy Julia session.

## Control the window

- Discover supported actions with `ui_actions(w)` and inspect `?click!`, `?load_file!`, or the installed package's UI documentation when needed. Prefer these public APIs over browser selectors or private callbacks for supported operations.
- Load an existing file with `load_file!(w, :sequence, path)`, `load_file!(w, :phantom, path)`, `load_file!(w, :scanner, path)`, or `load_file!(w, :configuration, path)`. Paths refer to the machine running Julia. Do not treat a failed load as permission to simulate the previously loaded inputs.
- Use `click!(w, action)` to inspect a view, for example `:view_sequence`, `:view_kspace`, or `:view_phantom`. Use `simulate!(w)` and `reconstruct!(w)` for computation. These calls update the UI, return their results, and throw on failure.
- For a long operation, retain its task: `task = @async simulate!(w)`. Inspect `ui_status(w)` for the action, state, progress, and any warning or error; use `fetch(task)` to retrieve the result or propagate the failure. Do not start another load, simulation, or reconstruction while the window is busy. `wait(w)` waits for the window to close, not for the operation to finish.
- Use a device returned by `get_devices()` if device selection is requested. Preserve the current backend and simulation/reconstruction settings unless the task calls for changing them.

## Verify and explain

- A successful operation means Julia's data/view update finished; it does not guarantee that the browser has painted the plot. Inspect the displayed view and take a screenshot before claiming the UI result is visible. Report relevant warnings rather than silently bypassing validation.
- For BIOS 214 student work, also follow [the course learning guidance](../bios214-pluto-student-code/SKILL.md). UI automation must still leave predictions, interpretation, and scientific validation with the student.
