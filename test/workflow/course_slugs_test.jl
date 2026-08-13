using Test

const SLUG_REPO_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
include(joinpath(SLUG_REPO_ROOT, "scripts", "course.jl"))

@testset "curriculum branch slugs" begin
    @test SLUGS == Dict(
        "F02" => "julia-arrays-and-tests",
        "F03-F04" => "vector-calculus-numerical-differentiation",
        "N01" => "linear-advection",
        "N02" => "nonlinear-advection",
        "N03" => "diffusion",
        "N04" => "advection-diffusion",
        "N05-N06" => "common-package-2d-advection",
        "N07" => "2d-advection-diffusion",
        "N08-N09" => "laplace-poisson",
    )
end
