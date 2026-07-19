using Test

const F01_REPO_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const F01_RUN_SCRIPT = joinpath(F01_REPO_ROOT, "exercises", "F01_first_pull_request", "run.jl")
const F01_TASK = joinpath(F01_REPO_ROOT, "exercises", "F01_first_pull_request", "TASK.md")
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

    @testset "manual branch to merge workflow is explicit and ordered" begin
        @test isfile(F01_TASK)
        if isfile(F01_TASK)
            task = read(F01_TASK, String)
            @test occursin(
                "https://t2lab-it.github.io/thermofluid-exercise-2026/assignments/F01.html",
                task,
            )
            @test occursin("- `test/student/F01.jl`", task)
            @test occursin("`course_progress.toml`だけ", task)
            @test occursin("F00からF01", task)
            @test occursin("F01で初めてcommit", task)
            @test occursin("`test/student/F01.jl`のsmoke TODO", task)
            @test occursin("代表的な挨拶", task)
            @test occursin(
                "git add course_progress.toml exercises/F01_first_pull_request/run.jl test/student/F01.jl learning_logs/F01.md",
                task,
            )
            @test occursin("完了条件", task)
            @test occursin("`test/student/F01.jl`を代表例へ変更", task)
            @test ordered_contract(task, [
                "git status --short",
                "F00からF01",
                "git switch -c exercise/F01-first-pull-request",
                "TODOを実装",
                "Pkg.test()",
                "公式出力：なし",
                "5. `learning_logs/templates/F01.md`を`learning_logs/F01.md`へコピー",
                "git commit",
                "git push",
                "8. GitHubで`exercise/F01-first-pull-request`から`main`へのPull Request",
                "9. Actions",
                "10. Pull RequestのFiles changedでdiff",
                "11. 完了条件を使ってセルフレビュー",
                "12. Pull Requestをmerge",
            ])
            @test !occursin("course.jl start F01", task)
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
