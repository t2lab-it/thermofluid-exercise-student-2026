using Test

const REPO_ROOT = normpath(joinpath(@__DIR__, ".."))

include(joinpath(REPO_ROOT, "scripts", "lib", "CourseWorkflow.jl"))
using .CourseWorkflow

function run_fixture_course_tests(task_test_root, state)
    for id in tests_to_run(state)
        path = joinpath(task_test_root, "$(id)_test.jl")
        isfile(path) || error("missing local test: $path")
        include(path)
    end
end

function run_course_tests(provided_root, student_root, state)
    for id in tests_to_run(state)
        provided = joinpath(provided_root, "$id.jl")
        isfile(provided) || error("missing provided course test: $provided")
        include(provided)

        student = joinpath(student_root, "$id.jl")
        isfile(student) && include(student)
    end
end

state = load_progress(joinpath(REPO_ROOT, "course_progress.toml"))
fixture_root = get(ENV, "COURSE_TASK_TEST_ROOT", nothing)
provided_root = get(ENV, "COURSE_PROVIDED_TEST_ROOT", joinpath(@__DIR__, "provided"))
student_root = get(ENV, "COURSE_STUDENT_TEST_ROOT", joinpath(@__DIR__, "student"))

if "--course-only" in ARGS
    if isnothing(fixture_root)
        isdir(provided_root) || error("provided course test root does not exist: $provided_root")
        run_course_tests(provided_root, student_root, state)
    else
        run_fixture_course_tests(fixture_root, state)
    end
else
    workflow_root = get(ENV, "COURSE_WORKFLOW_TEST_ROOT", joinpath(@__DIR__, "workflow"))
    workflow_files = sort(filter(
        path -> endswith(path, "_test.jl"),
        readdir(workflow_root; join=true),
    ))
    @testset "workflow tests" begin
        for path in workflow_files
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

    withenv("COURSE_NORMAL_PHASE" => "1") do
        if isnothing(fixture_root)
            isdir(provided_root) && run_course_tests(provided_root, student_root, state)
        else
            run_fixture_course_tests(fixture_root, state)
        end
    end
end
