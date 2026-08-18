import Pkg
using Dates
env = length(ARGS) >= 1 ? ARGS[1] : joinpath(homedir(), ".nlrFlow", "julia")
mkpath(env)
Pkg.activate(env)
packages = [
    "OrdinaryDiffEq", "SciMLSensitivity", "Lux", "Optimization",
    "OptimizationOptimisers", "OptimizationOptimJL", "ComponentArrays",
    "NeuralPDE", "ModelingToolkit", "SymbolicRegression", "CSV",
    "DataFrames", "JSON3", "StableRNGs", "LineSearches", "Optim", "Zygote"
]
for pkg in packages
    try
        Pkg.add(pkg)
    catch e
        @warn "Could not install Julia package" package=pkg exception=(e, catch_backtrace())
        rethrow(e)
    end
end
Pkg.precompile()
open(joinpath(env, "nlrflow_environment.txt"), "w") do io
    println(io, "Created: ", Dates.now())
    println(io, "Julia: ", VERSION)
    println(io, join(packages, "\n"))
end
println("nlrFlow SciML environment prepared at: ", env)
