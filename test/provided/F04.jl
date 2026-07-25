using Test

const F04_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const F04_RUN = joinpath(F04_ROOT, "exercises", "F04_numerical_differentiation", "run.jl")
const F04_LOG = joinpath(F04_ROOT, "learning_logs", "templates", "F04.md")

@testset "F04 numerical differentiation" begin
    @test isfile(F04_RUN)
    if isfile(F04_RUN)
        if !isdefined(Main, :F04NumericalDifferentiation)
            include(F04_RUN)
        end
        using .F04NumericalDifferentiation
        source = read(F04_RUN, String)
        @test count("TODO(F04):", source) == 3

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
        @test !isdir(joinpath(F04_ROOT, "results", "F04"))
    end

    @test isfile(F04_LOG)
    if isfile(F04_LOG)
        log = read(F04_LOG, String)
        for heading in (
            "## 実行前予想", "## 前進・後退・中心差分",
            "## 一次元の誤差と収束次数", "## ベクトル解析三公式の数値検証",
            "## 手計算・ForwardDiff・有限差分の役割", "## 自分のテスト",
            "## AI利用", "## diff・テスト・結果",
        )
            @test occursin(heading, log)
        end
    end
end
