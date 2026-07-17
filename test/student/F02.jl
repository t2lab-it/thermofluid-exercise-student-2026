using Test

const F02_STUDENT_RUN = normpath(joinpath(
    @__DIR__, "..", "..", "exercises", "F02_julia_arrays_and_tests", "run.jl",
))
if !isdefined(Main, :F02JuliaArraysAndTests)
    include(F02_STUDENT_RUN)
end

@testset "F02 student-authored example" begin
    # TODO(F02): replace this smoke check with one hand-computable example.
    @test isdefined(F02JuliaArraysAndTests, :mean_temperature)
end
