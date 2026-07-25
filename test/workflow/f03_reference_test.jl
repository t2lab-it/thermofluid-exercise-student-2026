using Test

const F03_REFERENCE_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const F03_REFERENCE_RUN = joinpath(
    F03_REFERENCE_ROOT,
    "exercises",
    "F03_vector_calculus",
    "run.jl",
)

include(F03_REFERENCE_RUN)
const F03Reference = F03VectorCalculus

@testset "F03 provided ForwardDiff reference" begin
    reference = F03Reference.automatic_reference((0.2, -0.3, 0.4))
    @test keys(reference) == (:gradient, :curl, :laplacian)
    @test all(isapprox.(reference.gradient,
        (1.396785564032526, 0.08758622398516933, 0.2831424512830345);
        atol=1e-12, rtol=1e-12))
    @test all(isapprox.(reference.curl,
        (-0.9778085783652466, -1.1669155212954077, -0.949557931661533);
        atol=1e-12, rtol=1e-12))
    @test isapprox(reference.laplacian, -0.2831424512830345;
        atol=1e-12, rtol=1e-12)
    @test :automatic_reference ∉ names(F03Reference)
    @test_throws ArgumentError F03Reference.automatic_reference((0.0, NaN, 0.0))
end
