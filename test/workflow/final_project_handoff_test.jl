using Test

const HANDOFF_REPO_ROOT = normpath(joinpath(@__DIR__, "..", ".."))

@testset "final project handoff" begin
    path = joinpath(HANDOFF_REPO_ROOT, "FINAL_PROJECT.md")
    @test isfile(path)
    source = isfile(path) ? read(path, String) : ""
    for identifier in (
        "thermofluid-project-base-2026", "git rev-parse HEAD", "test/student/",
        "learning_logs/", "results/", "API", "CI",
    )
        @test occursin(identifier, source)
    end
    for term in (
        "学生リポジトリ", "プロジェクトリポジトリ", "簡易テスト",
        "第三者レビュー担当者", "代替案",
    )
        @test occursin(term, source)
    end
end
