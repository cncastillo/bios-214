using Pluto

Pluto.run(
    auto_reload_from_file=true,
    launch_browser=false,
    notebook=isempty(ARGS) ? nothing : abspath(only(ARGS)),
)
