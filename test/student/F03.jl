using Test

const F03_STUDENT_RUN = normpath(joinpath(
    @__DIR__, "..", "..", "exercises", "F03_vector_calculus", "run.jl",
))
if !isdefined(Main, :F03VectorCalculus)
    include(F03_STUDENT_RUN)
end

@testset "F03 student-authored example" begin
    # TODO(F03): replace this smoke check with one hand-computable derivative or residual.
    @test isdefined(F03VectorCalculus, :centered_partial)
end
