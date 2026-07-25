using Test

const F04_STUDENT_RUN = normpath(
    joinpath(@__DIR__, "..", "..", "exercises", "F04_numerical_differentiation", "run.jl"),
)
if !isdefined(Main, :F04NumericalDifferentiation)
    include(F04_STUDENT_RUN)
end

@testset "F04 student-authored example" begin
    # STUDENT_TEST_REQUIRED(F04): add one independent hand-computable
    # difference case and explain which implementation error it detects.
    @test true # Replace this placeholder with the required independent case.
end
