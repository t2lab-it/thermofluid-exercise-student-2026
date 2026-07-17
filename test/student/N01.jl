using Test

const N01_STUDENT_RUN = normpath(joinpath(
    @__DIR__, "..", "..", "exercises", "N01_linear_advection", "run.jl",
))
if !isdefined(Main, :N01LinearAdvection)
    include(N01_STUDENT_RUN)
end

@testset "N01 student-authored numerical property" begin
    # TODO(N01): replace this smoke check with one hand-computable update or
    # one representative stable/unstable numerical property.
    @test isdefined(N01LinearAdvection, :simulate)
end
