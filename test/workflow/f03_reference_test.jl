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
    for point in ((0.2, -0.3, 0.4), (-0.7, 0.1, -0.2))
        reference = F03Reference.automatic_reference(point)
        @test keys(reference) == (:gradient, :curl, :laplacian)
        @test reference.gradient isa NTuple{3,Real}
        @test reference.curl isa NTuple{3,Real}
        @test isapprox(
            collect(reference.gradient),
            collect(F03Reference.gradient_scalar(point));
            atol=1e-12,
            rtol=1e-12,
        )
        @test isapprox(
            collect(reference.curl),
            collect(F03Reference.curl_vector(point));
            atol=1e-12,
            rtol=1e-12,
        )
        @test isapprox(
            reference.laplacian,
            F03Reference.laplacian_scalar(point);
            atol=1e-12,
            rtol=1e-12,
        )
    end
    @test :automatic_reference ∉ names(F03Reference)
    @test_throws ArgumentError F03Reference.automatic_reference((0.0, NaN, 0.0))
end
