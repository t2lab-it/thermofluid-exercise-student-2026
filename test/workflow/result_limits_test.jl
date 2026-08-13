using Test

const REPO_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
include(joinpath(REPO_ROOT, "scripts", "lib", "ResultLimits.jl"))
using .ResultLimits

contains_japanese_result_limit_text(text::AbstractString) =
    occursin(r"[ぁ-んァ-ヶ一-龠]", text)

function argument_error_text(action)
    try
        action()
    catch exception
        @test exception isa ArgumentError
        return sprint(showerror, exception)
    end
    @test false
    ""
end

function sparse_file(path, size)
    mkpath(dirname(path))
    open(path, "w") do output
        if size > 0
            seek(output, size - 1)
            write(output, UInt8(0))
        end
    end
    path
end

@testset "result size limits" begin
    @test FILE_LIMIT == 5 * 1024^2
    @test TASK_LIMIT == 10 * 1024^2
    @test TOTAL_LIMIT == 100 * 1024^2

    @testset "Japanese diagnostics preserve required identifiers" begin
        for (field, action) in (
            ("file_limit", () -> check_result_limits(pwd(); file_limit=-1)),
            ("task_limit", () -> check_result_limits(pwd(); task_limit=-1)),
            ("total_limit", () -> check_result_limits(pwd(); total_limit=-1)),
        )
            message = argument_error_text(action)
            @test contains_japanese_result_limit_text(message)
            @test occursin(field, message)
        end

        missing_root = joinpath(pwd(), "missing-results-root")
        message = argument_error_text(() -> check_result_limits(missing_root))
        @test contains_japanese_result_limit_text(message)
        @test occursin(missing_root, message)
    end

    @testset "injected byte boundaries" begin
        mktempdir() do root
            sparse_file(joinpath(root, "N01", "result.bin"), 5)
            @test isempty(check_result_limits(root; file_limit=5, task_limit=10, total_limit=20))

            sparse_file(joinpath(root, "N01", "too-large.bin"), 6)
            violations = check_result_limits(root; file_limit=5, task_limit=20, total_limit=20)
            @test all(contains_japanese_result_limit_text, violations)
            @test any(contains("too-large.bin"), violations)
            @test any(message -> occursin("6", message) && occursin("5", message), violations)
        end

        mktempdir() do root
            sparse_file(joinpath(root, "N01", "first.bin"), 5)
            sparse_file(joinpath(root, "N01", "second.bin"), 5)
            @test isempty(check_result_limits(root; file_limit=5, task_limit=10, total_limit=20))

            sparse_file(joinpath(root, "N01", "second.bin"), 6)
            violations = check_result_limits(root; file_limit=10, task_limit=10, total_limit=20)
            @test all(contains_japanese_result_limit_text, violations)
            @test any(contains("N01"), violations)
            @test any(message -> occursin("11", message) && occursin("10", message), violations)
        end

        mktempdir() do root
            sparse_file(joinpath(root, "N01", "result.bin"), 4)
            sparse_file(joinpath(root, "N02", "result.bin"), 4)
            @test isempty(check_result_limits(root; file_limit=5, task_limit=5, total_limit=8))

            sparse_file(joinpath(root, "N02", "result.bin"), 5)
            violations = check_result_limits(root; file_limit=5, task_limit=5, total_limit=8)
            @test all(contains_japanese_result_limit_text, violations)
            @test any(message -> occursin("9", message) && occursin("8", message), violations)
        end
    end

    @testset "production MiB boundaries" begin
        mktempdir() do root
            sparse_file(joinpath(root, "N01", "first.bin"), FILE_LIMIT)
            sparse_file(joinpath(root, "N01", "second.bin"), FILE_LIMIT)
            @test isempty(check_result_limits(root))
        end

        mktempdir() do root
            sparse_file(joinpath(root, "N01", "too-large.bin"), FILE_LIMIT + 1)
            violations = check_result_limits(root)
            @test all(contains_japanese_result_limit_text, violations)
            @test any(contains("too-large.bin"), violations)
        end

        mktempdir() do root
            sparse_file(joinpath(root, "N01", "first.bin"), FILE_LIMIT)
            sparse_file(joinpath(root, "N01", "second.bin"), FILE_LIMIT)
            sparse_file(joinpath(root, "N01", "one-byte.bin"), 1)
            violations = check_result_limits(root)
            @test all(contains_japanese_result_limit_text, violations)
            @test any(contains("N01"), violations)
        end
    end
end
