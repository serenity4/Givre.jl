using Anvil, Test, Logging
using Anvil: exit

!@isdefined(includet) && (includet = include)
includet("main.jl")

Logging.disable_logging(Logging.Info)
# Logging.disable_logging(Logging.BelowMinLevel)
ENV["JULIA_DEBUG"] = "Anvil"
# ENV["JULIA_DEBUG"] = "Anvil,CooperativeTasks"
# ENV["ANVIL_LOG_FRAMECOUNT"] = false
# ENV["ANVIL_LOG_KEY_PRESS"] = true
# ENV["ANVIL_RELEASE"] = true # may circumvent issues with validation layers

#= Known issues:
- `at(model_text, :center)` seems broken, as the dropdown background is not positioned correctly.
=# main()

@testset "Anvil.jl" begin
  include("layout.jl")
  include("bindings.jl")
  include("application.jl")
end;

using DataFrames
df = DataFrame(Anvil.app.ecs)
select(df, :Name, :Render, :Input)
select(df, :Name, :Z)
select(df, :Name, :Location)
df.Name .=> df.Input

GC.gc()
