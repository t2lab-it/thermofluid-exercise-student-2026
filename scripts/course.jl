include(joinpath(@__DIR__, "lib", "CourseWorkflow.jl"))
include(joinpath(@__DIR__, "lib", "ResultLimits.jl"))
include(joinpath(@__DIR__, "..", "exercises", "F00_environment", "run.jl"))

using .CourseWorkflow
using .F00Environment
using .ResultLimits

const SLUGS = Dict(
    "F02" => "julia-arrays-and-tests",
    "F03" => "vector-calculus",
    "F04" => "numerical-differentiation",
    "N01" => "linear-advection",
    "N02" => "nonlinear-advection",
    "N03" => "diffusion",
    "N04" => "advection-diffusion",
    "N05-N06" => "common-package-2d-advection",
    "N07" => "2d-advection-diffusion",
    "N08-N09" => "laplace-poisson",
)

const USAGE = """
Usage:
  julia --project=. $(joinpath("scripts", "course.jl")) preflight [--confirm-github --confirm-agent <copilot|codex|amazon-q>]
  julia --project=. $(joinpath("scripts", "course.jl")) start <ID>
  julia --project=. $(joinpath("scripts", "course.jl")) status
  julia --project=. $(joinpath("scripts", "course.jl")) check-results

Examples:
  julia --project=. $(joinpath("scripts", "course.jl")) start N05-N06
  julia --project=. $(joinpath("scripts", "course.jl")) start N08-N09
"""

git_output(root, arguments...) = readchomp(Cmd(`git $(arguments)`; dir=root))

function require_preflight(root)
    branch = git_output(root, "branch", "--show-current")
    branch == "main" ||
        throw(ArgumentError("course commands must start on main; current branch is $branch"))
    isempty(git_output(root, "status", "--porcelain")) ||
        throw(ArgumentError("working tree must be clean before starting an exercise"))
    nothing
end

function require_result_limits(root)
    results = joinpath(root, "results")
    isdir(results) || return nothing
    violations = check_result_limits(results)
    isempty(violations) || throw(ArgumentError(join(violations, '\n')))
    nothing
end

function require_local_tests(root)
    runner = joinpath("test", "runtests.jl")
    command = Cmd(Cmd([
        Base.julia_cmd().exec...,
        "--startup-file=no",
        "--project=.",
        runner,
        "--course-only",
    ]); dir=root)
    process = run(ignorestatus(command))
    process.exitcode == 0 ||
        throw(ArgumentError("local tests failed; fix the current exercise before advancing"))
    nothing
end

function show_status(root)
    state = load_progress(joinpath(root, "course_progress.toml"))
    completed = isempty(state.completed) ? "none" : join(state.completed, ", ")
    println("Current: $(state.current)")
    println("Completed: $completed")
end

function start_exercise(root, id; persist_progress=save_progress)
    progress_path = joinpath(root, "course_progress.toml")
    state = load_progress(progress_path)
    require_preflight(root)
    validate_transition(state, id)
    require_local_tests(root)
    require_result_limits(root)

    slug = get(SLUGS, id, nothing)
    isnothing(slug) &&
        throw(ArgumentError("no exercise branch slug is configured for $id"))
    branch = "exercise/$id-$slug"
    run(Cmd(`git switch -c $branch`; dir=root))
    advanced = ProgressState(
        state.schema_version,
        state.ordered,
        vcat(state.completed, [state.current]),
        id,
    )
    try
        persist_progress(progress_path, advanced)
    catch persistence_error
        try
            run(Cmd(`git switch main`; dir=root))
            run(Cmd(`git branch -D $branch`; dir=root))
        catch rollback_error
            throw(CompositeException([persistence_error, rollback_error]))
        end
        rethrow()
    end

    println("Started $id on $branch.")
    println("When your work is committed, publish it with:")
    println("  git push -u origin $branch")
    println("Then open a pull request for $branch in your hosting service.")
end

function main(
    arguments=ARGS;
    root=pwd(),
    preflight_report=nothing,
    preflight_collector=collect_preflight,
    persist_progress=save_progress,
    io=stdout,
)
    if arguments == ["--help"] || arguments == ["-h"] || isempty(arguments)
        print(USAGE)
        return 0
    end

    command = first(arguments)
    if command == "preflight"
        confirmations = parse_preflight_arguments(arguments[2:end])
        report = isnothing(preflight_report) ? preflight_collector() : preflight_report
        completed = run_f00_preflight(
            root;
            report,
            persist_progress,
            io,
            confirmations...,
        )
        attempted_completion = length(arguments) > 1
        return attempted_completion && !completed ? 1 : 0
    elseif command == "status" && length(arguments) == 1
        show_status(root)
    elseif command == "check-results" && length(arguments) == 1
        require_result_limits(root)
        println("Result size limits passed.")
    elseif command == "start" && length(arguments) == 2
        start_exercise(root, arguments[2])
    else
        throw(ArgumentError("invalid command\n$USAGE"))
    end
    0
end

if abspath(PROGRAM_FILE) == @__FILE__
    try
        exit(main())
    catch exception
        println(stderr, "error: ", sprint(showerror, exception))
        exit(1)
    end
end
