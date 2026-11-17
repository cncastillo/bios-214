using Pkg
Pkg.instantiate()
Pkg.precompile()
using BartIO
BartIO.bart(0, "version")
