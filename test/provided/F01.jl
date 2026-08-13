using Test

const F01_REPO_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const F01_RUN_SCRIPT = joinpath(F01_REPO_ROOT, "exercises", "F01_first_pull_request", "run.jl")

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
end
