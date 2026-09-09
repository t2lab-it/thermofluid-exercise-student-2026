using Test

if !isdefined(Main, :F03VectorCalculus)
    include(joinpath(@__DIR__, "F03.jl"))
end
if !isdefined(Main, :F04NumericalDifferentiation)
    include(joinpath(@__DIR__, "run.jl"))
end
using .F04NumericalDifferentiation

@testset "F03 vector calculus identities" begin
        p = (0.2, -0.3, 0.4)
        for name in (:gradient_scalar, :curl_vector, :laplacian_scalar)
            @test name in names(F03VectorCalculus)
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

end

@testset "F04 numerical differentiation" begin
        for difference in (forward_difference, backward_difference, centered_difference)
            @test difference(x -> 2x + 1, 0.4, 0.1) ≈ 2.0
            for h in (0.0, -0.1, Inf, NaN, true)
                @test_throws ArgumentError difference(identity, 0.4, h)
            end
            for x in (Inf, -Inf, NaN)
                @test_throws ArgumentError difference(identity, x, 0.1)
            end
        end

        reference_function(x) = sin(x) * exp(x)
        reference_derivative(x) = exp(x) * (sin(x) + cos(x))
        study = convergence_study(reference_function, reference_derivative, 0.4,
            [0.2, 0.1, 0.05, 0.025])
        @test all(ratio -> 1.7 <= ratio <= 2.3, study.forward_ratios)
        @test all(ratio -> 1.7 <= ratio <= 2.3, study.backward_ratios)
        @test all(ratio -> 3.7 <= ratio <= 4.3, study.centered_ratios)

        calls = Ref(0)
        function spy(f, x, h)
            calls[] += 1
            centered_difference(f, x, h)
        end
        centered_partial(q -> q[1]^2, (0.2, -0.3, 0.4), 1, 0.1;
            differentiator=spy)
        @test calls[] == 1

        coarse = verify_vector_identities(9)
        fine = verify_vector_identities(17)
        @test keys(coarse) == (:curl_gradient, :divergence_curl, :laplacian_identity)
        for key in keys(coarse)
            @test 0 < getproperty(fine, key) < getproperty(coarse, key)
            @test 3.0 <= getproperty(coarse, key) / getproperty(fine, key) <= 4.8
        end
end
