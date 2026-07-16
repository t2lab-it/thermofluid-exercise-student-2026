using Test

const REPO_ROOT = normpath(joinpath(@__DIR__, ".."))

if "--course-only" in ARGS
    include(joinpath(REPO_ROOT, "scripts", "lib", "CourseWorkflow.jl"))
    using .CourseWorkflow

    state = load_progress(joinpath(REPO_ROOT, "course_progress.toml"))
    task_test_root = get(ENV, "COURSE_TASK_TEST_ROOT", joinpath(@__DIR__, "tasks"))
    for id in tests_to_run(state)
        path = joinpath(task_test_root, "$(id)_test.jl")
        isfile(path) || error("missing local test: $path")
        include(path)
    end
else
    @testset "workflow tests" begin
        for filename in ("progress_test.jl", "result_limits_test.jl", "course_cli_test.jl")
            path = joinpath(@__DIR__, "workflow", filename)
            command = Cmd(Cmd([
                Base.julia_cmd().exec...,
                "--startup-file=no",
                "--project=.",
                path,
            ]); dir=REPO_ROOT)
            process = run(ignorestatus(command))
            @test process.exitcode == 0
        end
    end
end
