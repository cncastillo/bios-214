using Pkg

# Promote existing, pinned dependencies without updating the notebook's package graph.
Pkg.add([Pkg.PackageSpec(name="FFTW"), Pkg.PackageSpec(name="Preferences")]; preserve=Pkg.PRESERVE_ALL)
using Preferences
Preferences.set_preferences!("FFTW", "provider" => only(ARGS); force=true)
