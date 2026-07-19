using Test

const F01_REPO_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const F01_RUN_SCRIPT = joinpath(F01_REPO_ROOT, "exercises", "F01_first_pull_request", "run.jl")
const F01_LOG_TEMPLATE = joinpath(F01_REPO_ROOT, "learning_logs", "templates", "F01.md")

function ordered_contract(text, needles)
    ranges = [findfirst(needle, text) for needle in needles]
    all(!isnothing, ranges) || return false
    positions = [first(range) for range in ranges]
    issorted(positions) && all(diff(positions) .> 0)
end

@testset "F01 first pull request" begin
    @testset "stable greeting API" begin
        @test isfile(F01_RUN_SCRIPT)
        if isfile(F01_RUN_SCRIPT)
            if !isdefined(Main, :F01FirstPullRequest)
                include(F01_RUN_SCRIPT)
            end
            @test F01FirstPullRequest.student_greeting("Ryo") == "Hello, Ryo!"
            @test F01FirstPullRequest.student_greeting(SubString("  Araki  ", 1, 9)) ==
                "Hello, Araki!"
            @test_throws ArgumentError F01FirstPullRequest.student_greeting("   ")
            @test_throws MethodError F01FirstPullRequest.student_greeting(2026)
        end
    end

    @testset "F01 learning log is a summary, not a transcript" begin
        @test isfile(F01_LOG_TEMPLATE)
        if isfile(F01_LOG_TEMPLATE)
            learning_log = read(F01_LOG_TEMPLATE, String)
            @test ordered_contract(learning_log, [
                "実行前予想",
                "依頼内容",
                "重要な提案",
                "採用・修正・却下",
                "diff",
                "テスト",
                "結果",
                "理由",
            ])
            @test occursin("全対話", learning_log)
            @test occursin("不要", learning_log)
        end
    end
end
