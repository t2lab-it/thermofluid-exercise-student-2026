using Test
using TOML

const DEPENDENCY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))

@testset "student root dependency contract" begin
    project = TOML.parsefile(joinpath(DEPENDENCY_ROOT, "Project.toml"))
    @test Set(keys(project["deps"])) == Set([
        "ForwardDiff",
        "JuliaFormatter",
        "LinearAlgebra",
        "Plots",
        "TOML",
    ])
    @test project["compat"]["ForwardDiff"] == "1"
    @test project["compat"]["JuliaFormatter"] == "=2.10.1"
    @test project["compat"]["julia"] == "1.12.6"

    manifest = read(joinpath(DEPENDENCY_ROOT, "Manifest.toml"), String)
    @test occursin("julia_version = \"1.12.6\"", manifest)
    @test occursin("[[deps.ForwardDiff]]", manifest)
    @test occursin("[[deps.JuliaFormatter]]", manifest)
    @test !occursin("[[deps.CairoMakie]]", manifest)
end
