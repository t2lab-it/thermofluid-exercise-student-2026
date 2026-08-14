using Test

const ROOT = normpath(joinpath(@__DIR__, "..", ".."))
source(path) = read(joinpath(ROOT, path), String)

@testset "student public collaboration files" begin
    for path in ("LICENSE.md", "LICENSE-MIT.txt", "LICENSE-CC-BY-4.0.txt", "CONTRIBUTING.md")
        @test isfile(joinpath(ROOT, path))
    end
    readme = source("README.md")
    contribution = source("CONTRIBUTING.md")
    pull_request = source(".github/pull_request_template.md")
    workflow = source(".github/workflows/ci.yml")
    for term in ("現在", "非公開テンプレート", "原則公開", "非公開の例外", "LMS")
        @test occursin(term, readme)
    end
    for term in ("fork", "出典", "CC BY 4.0", "MIT", "非公開の連絡")
        @test occursin(term, contribution)
    end
    for content in (contribution, pull_request)
        @test occursin("合理的配慮", content)
        @test occursin("AI利用の全文ログ", content)
        @test occursin("生の会話記録", content)
        @test occursin("リポジトリに含めません", content)
        @test occursin("AI利用の要約", content)
    end
    for marker in ("sources_and_reuse", "publication_safety")
        @test occursin("contract-section: $marker", pull_request)
    end
    @test occursin("pull_request:", workflow)
    @test occursin("contents: read", workflow)
    @test !occursin("pull_request_target", workflow)
    @test !occursin(r"(?m)^\s*secrets\s*:", workflow)
end
