using Test

const F03_STUDENT_RUN =
    normpath(joinpath(@__DIR__, "..", "..", "exercises", "F03_vector_calculus", "run.jl"))
if !isdefined(Main, :F03VectorCalculus)
    include(F03_STUDENT_RUN)
end

@testset "F03 student-authored example" begin
    # STUDENT_TEST_REQUIRED(F03): use a point different from (0.2,-0.3,0.4)
    # and compare gradient, curl, and Laplacian with automatic_reference.
    @test true # Replace this placeholder with the required independent comparison.
end
