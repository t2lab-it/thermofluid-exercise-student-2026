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
        h = 0.1
        quadratic(q) = q[1]^2 + 2q[2] + 3q[3]

        @test isapprox(F03VectorCalculus.centered_partial(quadratic, p, 1, h), 0.4; atol=1e-12)
        @test isapprox(F03VectorCalculus.centered_partial(quadratic, p, 2, h), 2.0; atol=1e-12)
        @test isapprox(F03VectorCalculus.centered_partial(quadratic, p, 3, h), 3.0; atol=1e-12)

        @test all(isapprox.(
            F03VectorCalculus.curl_gradient_residual(p, h),
            (-2.919541147070742e-4, 4.65595243438921e-3, 0.0);
            atol=1e-12,
        ))
        @test isapprox(
            F03VectorCalculus.divergence_curl_residual(p, h),
            -1.092077525305879e-2;
            atol=1e-12,
        )
        @test isapprox(
            F03VectorCalculus.laplacian_identity_residual(p, h),
            1.4154764729020775e-3;
            atol=1e-12,
        )

        coarse = F03VectorCalculus.verify_identities(9)
        fine = F03VectorCalculus.verify_identities(17)
        @test keys(coarse) == (
            :curl_gradient,
            :divergence_curl,
            :laplacian_identity,
        )
        for key in keys(coarse)
            coarse_error = getproperty(coarse, key)
            fine_error = getproperty(fine, key)
            @test isfinite(coarse_error)
            @test isfinite(fine_error)
            @test 0 < fine_error < coarse_error
            @test 3.0 <= coarse_error / fine_error <= 4.8
        end

        for call in (
            () -> F03VectorCalculus.centered_partial(quadratic, p, true, h),
            () -> F03VectorCalculus.centered_partial(quadratic, p, 0, h),
            () -> F03VectorCalculus.centered_partial(quadratic, p, 4, h),
            () -> F03VectorCalculus.centered_partial(quadratic, p, 1, 0.0),
            () -> F03VectorCalculus.centered_partial(quadratic, p, 1, Inf),
            () -> F03VectorCalculus.centered_partial(
                quadratic, (0.0, NaN, 0.0), 1, h,
            ),
            () -> F03VectorCalculus.verify_identities(true),
            () -> F03VectorCalculus.verify_identities(2),
            () -> F03VectorCalculus.verify_identities(8),
        )
            @test_throws ArgumentError call()
        end

        run(`$(Base.julia_cmd()) --startup-file=no --project=$(F03_ROOT) $(F03_RUN)`)
        @test !isdir(joinpath(F03_ROOT, "results", "F03"))

        source = read(F03_RUN, String)
        @test !occursin("ThermofluidExercise", source)
    end

    @test isfile(F03_LOG)
    if isfile(F03_LOG)
        log = read(F03_LOG, String)
        for heading in (
            "## 手計算証明1：curl grad = 0",
            "## 手計算証明2：div curl = 0",
            "## 手計算証明3：div grad = Laplacian",
            "## 数値検証",
            "## 誤差比の解釈",
        )
            @test occursin(heading, log)
        end
        for proof_prompt in ("使用した定義", "添字の交換・縮約", "混合偏微分", "結論")
            @test occursin(proof_prompt, log)
        end
    end
end
