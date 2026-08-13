using Test

const F03_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const F03_RUN = joinpath(F03_ROOT, "exercises", "F03_vector_calculus", "run.jl")
const F03_OLD_ROOT = joinpath(F03_ROOT, "exercises", "F03_numerical_primer")
const F03_AUTOMATIC_REFERENCE = Symbol("automatic" * "_reference")
const F03_FORWARD_DIFF = "Forward" * "Diff"

@testset "F03 vector calculus identities" begin
    @test isfile(F03_RUN)
    @test !ispath(F03_OLD_ROOT)

    if isfile(F03_RUN)
        if !isdefined(Main, :F03VectorCalculus)
            include(F03_RUN)
        end
        p = (0.2, -0.3, 0.4)
        for name in (:gradient_scalar, :curl_vector, :laplacian_scalar)
            @test name in names(F03VectorCalculus)
        end
        for moved in (:centered_partial, :curl_gradient_residual,
                      :divergence_curl_residual, :laplacian_identity_residual,
                      :verify_identities)
            @test moved ∉ names(F03VectorCalculus; all=true)
        end
        @test all(isapprox.(F03VectorCalculus.gradient_scalar(p),
            (1.396785564032526, 0.08758622398516933, 0.2831424512830345);
            atol=1e-12, rtol=1e-12))
        @test all(isapprox.(F03VectorCalculus.curl_vector(p),
            (-0.9778085783652466, -1.1669155212954077, -0.949557931661533);
            atol=1e-12, rtol=1e-12))
        @test isapprox(F03VectorCalculus.laplacian_scalar(p), -0.2831424512830345;
            atol=1e-12, rtol=1e-12)

        for call in (
            () -> F03VectorCalculus.gradient_scalar((0.0, NaN, 0.0)),
            () -> F03VectorCalculus.curl_vector((0.0, Inf, 0.0)),
            () -> F03VectorCalculus.laplacian_scalar((0.0, 0.0)),
        )
            @test_throws ArgumentError call()
        end

        @test !isdir(joinpath(F03_ROOT, "results", "F03"))

        source = read(F03_RUN, String)
        @test F03_AUTOMATIC_REFERENCE ∉ names(F03VectorCalculus; all=true)
        @test !occursin("TODO(F03):", source)
        @test !occursin(F03_FORWARD_DIFF, source)
        @test !occursin("ThermofluidExercise", source)
    end
end
