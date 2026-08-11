using Test

const TOOLING_REPO_ROOT = normpath(joinpath(@__DIR__, "..", ".."))

@testset "student editor and CI tooling contract" begin
    extensions_path = joinpath(TOOLING_REPO_ROOT, ".vscode", "extensions.json")
    settings_path = joinpath(TOOLING_REPO_ROOT, ".vscode", "settings.json")
    ci_path = joinpath(TOOLING_REPO_ROOT, ".github", "workflows", "ci.yml")
    readme_path = joinpath(TOOLING_REPO_ROOT, "README.md")

    @test isfile(extensions_path)
    @test isfile(settings_path)

    extensions = read(extensions_path, String)
    @test occursin("\"julialang.language-julia\"", extensions)
    @test !occursin("ms-ceintl.vscode-language-pack-ja", extensions)

    settings = read(settings_path, String)
    for marker in (
        "\"[julia]\"",
        "\"editor.defaultFormatter\": \"julialang.language-julia\"",
        "\"editor.formatOnSave\": true",
        "\"editor.insertSpaces\": true",
        "\"editor.tabSize\": 4",
        "\"editor.bracketPairColorization.enabled\": true",
        "\"editor.guides.bracketPairs\": true",
        "\"files.trimTrailingWhitespace\": true",
        "\"files.insertFinalNewline\": true",
        "\"julia.lint.run\": true",
    )
        @test occursin(marker, settings)
    end

    ci = read(ci_path, String)
    @test occursin("pull_request:", ci)
    @test occursin("permissions:\n  contents: read", ci)
    instantiate = findfirst("Instantiate environment", ci)
    format_check = findfirst("Check Julia formatting", ci)
    tests = findfirst("Run tests", ci)
    @test !isnothing(instantiate)
    @test !isnothing(format_check)
    @test !isnothing(tests)
    @test first(instantiate) < first(format_check) < first(tests)
    @test occursin("julia --project=. scripts/format.jl --check", ci)
    @test occursin(
        "julia --project=. -e 'using Pkg; Pkg.instantiate(; allow_autoprecomp=false)'",
        ci,
    )
    @test occursin("julia --startup-file=no --project=. test/runtests.jl", ci)
    @test !occursin("Pkg.test()", ci)

    readme = read(readme_path, String)
    for marker in (
        "Julia拡張`julialang.language-julia`（必須）",
        "Japanese Language Pack（任意）",
        "julia --project=. scripts/format.jl\n",
        "git diff\n",
        "julia --project=. -e 'using Pkg; Pkg.test()'",
        "CIは整形状態を検査しますが、ファイルの編集やpushは行いません。",
    )
        @test occursin(marker, readme)
    end
end
