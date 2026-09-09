using Test

const SELECTION_REPO_ROOT = normpath(joinpath(@__DIR__, "..", ".."))

function selected_run(; arguments=String[], failure=nothing)
    mktempdir() do root
        for relative in ("test/runtests.jl", "scripts/lib/CourseWorkflow.jl", "scripts/lib/ResultLimits.jl", "course_progress.toml")
            path = joinpath(root, relative)
            mkpath(dirname(path))
            cp(joinpath(SELECTION_REPO_ROOT, relative), path)
        end
        for kind in ("provided", "student", "workflow")
            directory = joinpath(root, "test", kind)
            mkpath(directory)
            name = kind == "workflow" ? "probe_test.jl" : "F00.jl"
            write(joinpath(directory, name), failure == kind ? "error(\"$kind failure\")" : "println(\"selected $kind\")")
            kind == "workflow" || write(joinpath(directory, "F01.jl"), "error(\"future task ran\")")
        end
        if failure == "results"
            mkpath(joinpath(root, "results", "F00"))
            open(joinpath(root, "results", "F00", "oversized.bin"), "w") do io
                truncate(io, 5 * 1024^2 + 1)
            end
        elseif failure == "missing"
            rm(joinpath(root, "test", "provided"); recursive=true)
        end
        output = IOBuffer()
        process = run(pipeline(ignorestatus(`$(Base.julia_cmd()) --startup-file=no $(joinpath(root, "test", "runtests.jl")) $arguments`); stdout=output, stderr=output))
        (exitcode=process.exitcode, output=String(take!(output)))
    end
end

@testset "student tests and maintenance tests have separate entrypoints" begin
    for arguments in (String[], ["--course-only"])
        result = selected_run(; arguments)
        @test result.exitcode == 0
        @test occursin("selected provided", result.output)
        @test occursin("selected student", result.output)
        @test !occursin("selected workflow", result.output)
        @test !occursin("future task ran", result.output)
    end
    result = selected_run(arguments=["--maintenance"])
    @test result.exitcode == 0
    @test occursin("selected workflow", result.output)
    @test occursin("selected provided", result.output)
    for failure in ("provided", "student", "results", "missing")
        @test selected_run(; failure).exitcode != 0
    end
    @test selected_run(arguments=["--maintenance"], failure="workflow").exitcode != 0
    @test selected_run(arguments=["--unknown"]).exitcode != 0
end
