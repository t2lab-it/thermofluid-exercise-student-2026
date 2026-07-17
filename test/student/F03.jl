using Test

const F03_STUDENT_RUN = normpath(joinpath(
    @__DIR__, "..", "..", "exercises", "F03_numerical_primer", "run.jl",
))
if !isdefined(Main, :F03NumericalPrimer)
    include(F03_STUDENT_RUN)
end

@testset "F03 student-authored example" begin
    # TODO(F03): replace this smoke check with one hand-computable linear example.
    @test isdefined(F03NumericalPrimer, :uniform_grid)
end
