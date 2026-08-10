using Test

const HANDOFF_REPO_ROOT = normpath(joinpath(@__DIR__, "..", ".."))

@testset "final project handoff" begin
    path = joinpath(HANDOFF_REPO_ROOT, "FINAL_PROJECT.md")
    @test isfile(path)
    source = isfile(path) ? read(path, String) : ""
    for phrase in (
        "別のproject repository", "source commit", "参照元", "変更点",
        "追加した検証", "private repositoryのURL", "最終成果物は置きません",
    )
        @test occursin(phrase, source)
    end
end
