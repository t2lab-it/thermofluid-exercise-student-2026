using Test

const F03_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const F03_RUN = joinpath(F03_ROOT, "exercises", "F03_vector_calculus", "run.jl")
const F03_OLD_ROOT = joinpath(F03_ROOT, "exercises", "F03_numerical_primer")
const F03_LOG = joinpath(F03_ROOT, "learning_logs", "templates", "F03.md")

@testset "F03 vector calculus identities" begin
    @test isfile(F03_RUN)
    @test !ispath(F03_OLD_ROOT)

    if isfile(F03_RUN)
        if !isdefined(Main, :F03VectorCalculus)
            include(F03_RUN)
        end
        p = (0.2, -0.3, 0.4)
        reference = F03VectorCalculus.automatic_reference(p)
        for name in (:gradient_scalar, :curl_vector, :laplacian_scalar)
            @test name in names(F03VectorCalculus)
        end
        for moved in (:centered_partial, :curl_gradient_residual,
                      :divergence_curl_residual, :laplacian_identity_residual,
                      :verify_identities)
            @test moved ∉ names(F03VectorCalculus; all=true)
        end
        @test all(isapprox.(F03VectorCalculus.gradient_scalar(p), reference.gradient;
            atol=1e-12, rtol=1e-12))
        @test all(isapprox.(F03VectorCalculus.curl_vector(p), reference.curl;
            atol=1e-12, rtol=1e-12))
        @test isapprox(F03VectorCalculus.laplacian_scalar(p), reference.laplacian;
            atol=1e-12, rtol=1e-12)

        for call in (
            () -> F03VectorCalculus.gradient_scalar((0.0, NaN, 0.0)),
            () -> F03VectorCalculus.curl_vector((0.0, Inf, 0.0)),
            () -> F03VectorCalculus.laplacian_scalar((0.0, 0.0)),
        )
            @test_throws ArgumentError call()
        end

        run(`$(Base.julia_cmd()) --startup-file=no --project=$(F03_ROOT) $(F03_RUN)`)
        @test !isdir(joinpath(F03_ROOT, "results", "F03"))

        source = read(F03_RUN, String)
        @test count("TODO(F03):", source) == 3
        @test !occursin("ThermofluidExercise", source)
    end

    @test isfile(F03_LOG)
    if isfile(F03_LOG)
        log = read(F03_LOG, String)
        for heading in (
            "## 完全証明：curl grad = 0",
            "## 構造確認：div curl = 0",
            "## 成分確認：div grad = Laplacian",
            "## 解析式のJulia実装",
            "## ForwardDiffによる参照値",
            "## 自分のテスト",
        )
            @test occursin(heading, log)
        end
        for proof_prompt in ("使用した定義", "添字の交換・縮約", "成分和の展開", "結論")
            @test occursin(proof_prompt, log)
        end
        for removed in ("n=9", "n=17", "粗格子／細格子", "数値検証")
            @test !occursin(removed, log)
        end
    end
end
