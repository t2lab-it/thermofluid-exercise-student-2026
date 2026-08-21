using Test
using TOML

const DEPENDENCY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const FORWARD_DIFF = "Forward" * "Diff"

@testset "student root dependency contract" begin
    project = TOML.parsefile(joinpath(DEPENDENCY_ROOT, "Project.toml"))
    @test Set(keys(project["deps"])) == Set([
        "LinearAlgebra",
        "Plots",
        "TOML",
    ])
    @test !haskey(project["compat"], FORWARD_DIFF)
    @test project["compat"]["julia"] == "1.12.6"

    manifest = read(joinpath(DEPENDENCY_ROOT, "Manifest.toml"), String)
    @test occursin("julia_version = \"1.12.6\"", manifest)
    @test !occursin("[[deps.$FORWARD_DIFF]]", manifest)
    @test !occursin("[[deps.CairoMakie]]", manifest)
end
