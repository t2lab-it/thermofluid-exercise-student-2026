using Test

const REPO_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
include(joinpath(REPO_ROOT, "scripts", "lib", "CourseWorkflow.jl"))
using .CourseWorkflow

const EXPECTED_UNITS = [
    "F00", "F01", "F02", "F03-F04",
    "N01", "N02", "N03", "N04", "N05-N06", "N07", "N08-N09",
]

@testset "course progress" begin
    @test ORDERED_UNITS == EXPECTED_UNITS
    @test TASK_IDS_BY_UNIT["N05-N06"] == ["N05", "N06"]
    @test TASK_IDS_BY_UNIT["F03-F04"] == ["F03", "F04"]
    @test TASK_IDS_BY_UNIT["N08-N09"] == ["N08", "N09"]

    state = load_progress(joinpath(REPO_ROOT, "course_progress.toml"))
    @test state.schema_version == 2
    @test state.current == "F00"
    @test state.completed == String[]
    @test tests_to_run(state) == ["F00"]

    advanced = ProgressState(2, ORDERED_UNITS, ["F00", "F01"], "F02")
    @test tests_to_run(advanced) == ["F00", "F01", "F02"]
    @test validate_transition(advanced, "F03-F04") === nothing
    @test_throws ArgumentError validate_transition(advanced, "N01")

    f03_f04 = ProgressState(2, EXPECTED_UNITS, ["F00", "F01", "F02"], "F03-F04")
    @test tests_to_run(f03_f04)[end-1:end] == ["F03", "F04"]
    @test validate_transition(f03_f04, "N01") === nothing
    @test_throws ArgumentError validate_transition(f03_f04, "F04")

    n05_n06 = ProgressState(
        2,
        EXPECTED_UNITS,
        EXPECTED_UNITS[1:8],
        "N05-N06",
    )
    @test tests_to_run(n05_n06)[end-1:end] == ["N05", "N06"]
    @test validate_transition(n05_n06, "N07") === nothing
    @test_throws ArgumentError validate_transition(n05_n06, "N06")

    @testset "strict TOML validation" begin
        valid = Dict(
            "schema_version" => 2,
            "ordered" => EXPECTED_UNITS,
            "completed" => ["F00", "F01"],
            "current" => "F02",
        )

        function write_progress(values)
            path, io = mktemp()
            close(io)
            open(path, "w") do output
                for key in ("schema_version", "ordered", "completed", "current")
                    value = values[key]
                    if value isa AbstractVector
                        encoded = join((repr(item) for item in value), ", ")
                        println(output, key, " = [", encoded, "]")
                    else
                        println(output, key, " = ", repr(value))
                    end
                end
            end
            path
        end

        for invalid in (
            merge(valid, Dict("schema_version" => 1)),
            merge(valid, Dict("schema_version" => true)),
            merge(valid, Dict("ordered" => EXPECTED_UNITS[1:end-1])),
            merge(valid, Dict("ordered" => vcat(EXPECTED_UNITS, ["N11"]))),
            merge(valid, Dict("ordered" => [EXPECTED_UNITS[2], EXPECTED_UNITS[1], EXPECTED_UNITS[3:end]...])),
            merge(valid, Dict("ordered" => vcat(EXPECTED_UNITS[1:end-1], ["N07"]))),
            merge(valid, Dict("completed" => ["F00", "F00"])),
            merge(valid, Dict("completed" => ["F00", "F02"])),
            merge(valid, Dict("completed" => ["F00", "F01", "F02"])),
        )
            path = write_progress(invalid)
            try
                @test_throws ArgumentError load_progress(path)
            finally
                rm(path; force=true)
            end
        end
    end

    @testset "atomic round trip" begin
        mktempdir() do directory
            path = joinpath(directory, "course_progress.toml")
            expected = ProgressState(2, ORDERED_UNITS, ["F00", "F01"], "F02")
            @test save_progress(path, expected) === nothing
            actual = load_progress(path)
            @test actual.schema_version == expected.schema_version
            @test actual.ordered == expected.ordered
            @test actual.completed == expected.completed
            @test actual.current == expected.current
            @test readdir(directory) == ["course_progress.toml"]
        end
    end
end
