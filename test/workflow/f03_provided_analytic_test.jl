using Test

const F03_ANALYTIC_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const F03_ANALYTIC_RUN = joinpath(
    F03_ANALYTIC_ROOT,
    "exercises",
    "F03_vector_calculus",
    "run.jl",
)

include(F03_ANALYTIC_RUN)
const F03_AUTOMATIC_REFERENCE = Symbol("automatic" * "_reference")
const F03_FORWARD_DIFF = "Forward" * "Diff"
const F03Analytic = F03VectorCalculus

@testset "F03 supplied analytic vector fields" begin
    point = (0.2, -0.3, 0.4)
    @test all(isapprox.(F03Analytic.gradient_scalar(point),
        (1.396785564032526, 0.08758622398516933, 0.2831424512830345);
        atol=1e-12, rtol=1e-12))
    @test all(isapprox.(F03Analytic.curl_vector(point),
        (-0.9778085783652466, -1.1669155212954077, -0.949557931661533);
        atol=1e-12, rtol=1e-12))
    @test isapprox(F03Analytic.laplacian_scalar(point), -0.2831424512830345;
        atol=1e-12, rtol=1e-12)
    @test F03_AUTOMATIC_REFERENCE ∉ names(F03Analytic; all=true)

    source = read(F03_ANALYTIC_RUN, String)
    @test !occursin(F03_FORWARD_DIFF, source)
    @test !occursin("TODO(F03):", source)
end
