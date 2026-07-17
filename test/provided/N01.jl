using Test
using TOML

const N01_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const N01_RUN = joinpath(N01_ROOT, "exercises", "N01_linear_advection", "run.jl")
const N01_TASK = joinpath(N01_ROOT, "exercises", "N01_linear_advection", "TASK.md")
const N01_LOG = joinpath(N01_ROOT, "learning_logs", "templates", "N01.md")

@testset "N01 self-contained linear advection" begin
    project = TOML.parsefile(joinpath(N01_ROOT, "Project.toml"))
    @test Set(keys(project["deps"])) == Set(["Plots", "TOML"])
    @test !occursin("CairoMakie", read(joinpath(N01_ROOT, "Manifest.toml"), String))

    @test isfile(N01_RUN)
    if isfile(N01_RUN)
        source = read(N01_RUN, String)
        @test !occursin("ThermofluidExercise", source)
        @test !occursin("Vector{Vector", source)
        for name in (
            :rectangular_initial_condition, :apply_boundary!, :upwind_step!, :centered_step!,
            :simulate, :write_summary, :make_plots, :main,
        )
            @test occursin(string(name), source)
        end

        if !isdefined(Main, :N01LinearAdvection)
            include(N01_RUN)
        end
        N01 = N01LinearAdvection

        x = collect(range(0.0, 2.0; length=5))
        @test N01.rectangular_initial_condition(x) == [1.0, 2.0, 2.0, 1.0, 1.0]
        @test_throws ArgumentError N01.rectangular_initial_condition([0.0, NaN, 1.0])

        boundary = fill(99.0, 5)
        @test N01.apply_boundary!(boundary; left_value=1.0) === boundary
        @test boundary[1] == 1.0
        @test boundary[end] == boundary[end - 1]

        old = [1.0, 2.0, 4.0, 8.0]
        old_copy = copy(old)
        new = similar(old)
        N01.upwind_step!(new, old, 1.0, 0.25, 0.5)
        @test new[2] == 1.5
        @test old == old_copy
        N01.centered_step!(new, old, 1.0, 0.25, 0.5)
        @test new[2] == 1.25
        @test old == old_copy

        constant = fill(3.0, 7)
        constant_new = similar(constant)
        N01.upwind_step!(constant_new, constant, 1.0, 0.1, 0.2)
        N01.apply_boundary!(constant_new; left_value=3.0)
        @test constant_new == constant
        N01.centered_step!(constant_new, constant, 1.0, 0.1, 0.2)
        N01.apply_boundary!(constant_new; left_value=3.0)
        @test constant_new == constant

        stable = N01.simulate(; scheme=:upwind)
        unstable = N01.simulate(; scheme=:centered)
        expected_keys = (:x, :u0, :u, :dx, :dt, :steps, :cfl, :minimum, :maximum)
        @test keys(stable) == expected_keys
        @test stable.x[1] == 0.0 && stable.x[end] == 2.0 && length(stable.x) == 81
        @test stable.u !== stable.u0
        @test stable.minimum >= 1.0 - 100eps()
        @test stable.maximum <= 2.0 + 100eps()
        @test unstable.minimum < 1.0 || unstable.maximum > 2.0
        @test unstable.maximum - unstable.minimum > stable.maximum - stable.minimum
        @test isapprox(stable.dt * stable.steps, 0.5; atol=100eps())
        @test isapprox(stable.cfl, stable.dt / stable.dx; atol=100eps())
        adjusted = N01.simulate(; scheme=:upwind, nx=20, c=1.0, cfl=0.6, t_final=0.37)
        @test isapprox(adjusted.dt * adjusted.steps, 0.37; atol=100eps())
        @test adjusted.cfl <= 0.6 + 100eps()

        for arguments in (
            (; scheme=:unknown), (; scheme=:upwind, nx=2), (; scheme=:upwind, c=0.0),
            (; scheme=:upwind, c=-1.0), (; scheme=:upwind, cfl=0.0),
            (; scheme=:upwind, cfl=1.1), (; scheme=:upwind, t_final=0.0),
        )
            @test_throws ArgumentError N01.simulate(; arguments...)
        end
        @test_throws ArgumentError N01.upwind_step!(old, old, 1.0, 0.1, 0.2)
        @test_throws ArgumentError N01.centered_step!(old, old, 1.0, 0.1, 0.2)

        output_dir = mktempdir()
        outputs = N01.main(; output_dir, nx=21, c=1.0, cfl=0.5, t_final=0.1)
        @test outputs.summary_path == joinpath(output_dir, "summary.toml")
        @test outputs.plot_paths.upwind == joinpath(output_dir, "upwind.png")
        @test outputs.plot_paths.centered == joinpath(output_dir, "centered-euler.png")
        for path in (outputs.summary_path, outputs.plot_paths.upwind, outputs.plot_paths.centered)
            @test isfile(path)
            @test filesize(path) <= 5 * 1024^2
        end
        @test sum(filesize, readdir(output_dir; join=true)) <= 10 * 1024^2
        summary = TOML.parsefile(outputs.summary_path)
        @test Set(keys(summary)) == Set(["course_id", "grid", "upwind", "centered_euler"])
        @test summary["course_id"] == "N01"
        @test summary["grid"]["nx"] == 21
        for section in ("upwind", "centered_euler")
            @test all(key -> haskey(summary[section], key), [
                "scheme", "cfl", "dt", "steps", "minimum", "maximum",
                "overshoot", "undershoot",
            ])
        end
    end

    @test isfile(N01_TASK)
    if isfile(N01_TASK)
        task = read(N01_TASK, String)
        @test occursin("https://t2lab-it.github.io/thermofluid-exercise-2026/assignments/N01.html", task)
        @test occursin("julia --project=. scripts/course.jl start N01", task)
        @test occursin("self-contained", lowercase(task))
        @test occursin("風上差分", task) && occursin("安定", task)
        @test occursin("中心差分", task) && occursin("意図的", task) && occursin("不安定", task)
        @test occursin("results/N01/upwind.png", task)
        @test occursin("results/N01/centered-euler.png", task)
        @test occursin("results/N01/summary.toml", task)
        @test occursin("デバッグ補助", task)
        @test occursin("秘密", task)
        @test !occursin("CairoMakie", task)
    end
    @test isfile(N01_LOG)
end
