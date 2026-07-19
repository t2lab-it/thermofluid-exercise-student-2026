using Test

const F03_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const F03_RUN = joinpath(F03_ROOT, "exercises", "F03_numerical_primer", "run.jl")
const F03_TASK = joinpath(F03_ROOT, "exercises", "F03_numerical_primer", "TASK.md")
const F03_LOG = joinpath(F03_ROOT, "learning_logs", "templates", "F03.md")

@testset "F03 numerical primer" begin
    @test isfile(F03_RUN)
    if isfile(F03_RUN)
        if !isdefined(Main, :F03NumericalPrimer)
            include(F03_RUN)
        end

        grid = F03NumericalPrimer.uniform_grid(0.0, 1.0, 3)
        @test grid == [0.0, 0.5, 1.0]
        @test F03NumericalPrimer.uniform_grid(Float32(0), Float32(1), 3) isa Vector{Float32}
        @test_throws ArgumentError F03NumericalPrimer.uniform_grid(0.0, 1.0, 1)
        @test_throws ArgumentError F03NumericalPrimer.uniform_grid(0.0, 1.0, true)
        @test_throws ArgumentError F03NumericalPrimer.uniform_grid(1.0, 1.0, 3)
        @test_throws ArgumentError F03NumericalPrimer.uniform_grid(2.0, 1.0, 3)
        @test_throws ArgumentError F03NumericalPrimer.uniform_grid(NaN, 1.0, 3)
        @test_throws ArgumentError F03NumericalPrimer.uniform_grid(0.0, Inf, 3)

        u = [1.0, 2.0, 4.0, 8.0]
        original = copy(u)
        @test F03NumericalPrimer.backward_difference_at(u, 3, 0.5) == 4.0
        @test F03NumericalPrimer.centered_difference_at(u, 3, 0.5) == 6.0
        @test u == original

        x = collect(range(0.0, 1.0; length=6))
        linear = 3 .* x .+ 2
        dx = x[2] - x[1]
        @test all(i -> isapprox(
            F03NumericalPrimer.backward_difference_at(linear, i, dx), 3.0; atol=100eps(),
        ), 2:length(linear))
        @test all(i -> isapprox(
            F03NumericalPrimer.centered_difference_at(linear, i, dx), 3.0; atol=100eps(),
        ), 2:(length(linear) - 1))

        for bad_dx in (0.0, -0.1, NaN, Inf)
            @test_throws ArgumentError F03NumericalPrimer.backward_difference_at(u, 2, bad_dx)
            @test_throws ArgumentError F03NumericalPrimer.centered_difference_at(u, 2, bad_dx)
        end
        for bad_i in (true, 0, 1, 5)
            @test_throws ArgumentError F03NumericalPrimer.backward_difference_at(u, bad_i, 0.5)
        end
        for bad_i in (true, 0, 1, 4, 5)
            @test_throws ArgumentError F03NumericalPrimer.centered_difference_at(u, bad_i, 0.5)
        end
        @test_throws ArgumentError F03NumericalPrimer.backward_difference_at([1.0, NaN], 2, 1.0)
        @test_throws ArgumentError F03NumericalPrimer.centered_difference_at([1.0, 2.0, Inf], 2, 1.0)
    end

    @test isfile(F03_TASK)
    if isfile(F03_TASK)
        task = read(F03_TASK, String)
        @test occursin("https://t2lab-it.github.io/thermofluid-exercise-2026/assignments/F03.html", task)
        @test occursin("julia --project=. scripts/course.jl start F03", task)
        @test occursin("julia --project=. -e 'using Pkg; Pkg.test()'", task)
        @test occursin("(u[i] - u[i - 1]) / dx", task)
        @test occursin("(u[i + 1] - u[i - 1]) / (2 * dx)", task)
        @test occursin("Juliaの`u[i]`", task) && occursin("x_i", task)
        @test occursin("公式出力：なし", task)
        @test occursin("test/student/F03.jl", task)
        @test occursin("learning_logs/F03.md", task)
        @test occursin("src/", task) && occursin("N01", task)
    end

    @test isfile(F03_LOG)
    if isfile(F03_RUN)
        source = read(F03_RUN, String)
        @test !occursin("ThermofluidExercise", source)
    end
end
