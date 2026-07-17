using Test

const F02_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const F02_RUN = joinpath(F02_ROOT, "exercises", "F02_julia_arrays_and_tests", "run.jl")
const F02_TASK = joinpath(F02_ROOT, "exercises", "F02_julia_arrays_and_tests", "TASK.md")
const F02_LOG = joinpath(F02_ROOT, "learning_logs", "templates", "F02.md")

@testset "F02 arrays, functions, and tests" begin
    @test isfile(F02_RUN)
    if isfile(F02_RUN)
        if !isdefined(Main, :F02JuliaArraysAndTests)
            include(F02_RUN)
        end
        temperatures = [10.0, 12.0, 14.0, 16.0]
        original = copy(temperatures)
        @test F02JuliaArraysAndTests.mean_temperature(temperatures) == 13.0
        @test F02JuliaArraysAndTests.mean_temperature(1:4) == 2.5
        @test F02JuliaArraysAndTests.mean_temperature(BigFloat[1, 2, 3]) isa BigFloat

        anomalies = F02JuliaArraysAndTests.temperature_anomaly(temperatures)
        @test anomalies == [-3.0, -1.0, 1.0, 3.0]
        @test isapprox(sum(anomalies) / length(anomalies), 0; atol=100eps())
        @test temperatures == original
        @test anomalies !== temperatures

        for invalid in (Float64[], [1.0, Inf], [NaN, 2.0])
            @test_throws ArgumentError F02JuliaArraysAndTests.mean_temperature(invalid)
            @test_throws ArgumentError F02JuliaArraysAndTests.temperature_anomaly(invalid)
        end
        @test_throws MethodError F02JuliaArraysAndTests.mean_temperature(["cold", "hot"])
    end

    @test isfile(F02_TASK)
    if isfile(F02_TASK)
        task = read(F02_TASK, String)
        @test occursin("https://t2lab-it.github.io/thermofluid-exercise-2026/assignments/F02.html", task)
        @test occursin("F01", task) && occursin("merge", task) && occursin("clean", task)
        @test occursin("julia --project=. scripts/course.jl start F02", task)
        @test occursin("julia --project=. -e 'using Pkg; Pkg.test()'", task)
        @test occursin("公式出力：なし", task)
        @test occursin("test/student/F02.jl", task)
        @test occursin("learning_logs/F02.md", task)
    end

    @test isfile(F02_LOG)
end
