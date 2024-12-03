# Compile USDX Song Assistant to binary using PackageCompiler.jl
#
#
# This script compiles the USDX Song Assistant to a executable.
#
# To build your binary, install the following dependencies:
# using Pkg; Pkg.add("PackageCompiler")
#
# Then run this script `julia compile-package.jl`
# On success, a directory called bin with an executable binary is created.
#
# More details on package compiler:
# https://julialang.github.io/PackageCompiler.jl/dev/apps.html


using Pkg
rm("UsdxSongAssistant", recursive=true, force=true)
rm("UsdxSongAssistantCompiled", recursive=true, force=true)
Pkg.generate("UsdxSongAssistant")

using PackageCompiler
create_app("UsdxSongAssistant", "UsdxSongAssistantCompiled", filter_stdlibs=true)
