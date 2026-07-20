if !isdefined(Main, :CourseWorkflow)
    include(joinpath(@__DIR__, "..", "..", "scripts", "lib", "CourseWorkflow.jl"))
end

module F00Environment

using Main.CourseWorkflow

export ObservedCheck,
    PreflightReport,
    SUPPORTED_AGENTS,
    collect_preflight,
    parse_preflight_arguments,
    print_preflight,
    run_f00_preflight

const REQUIRED_JULIA_VERSION = v"1.12.6"
const SUPPORTED_AGENTS = ("copilot", "codex", "amazon-q")

struct ObservedCheck
    id::Symbol
    passed::Bool
    observed::String
    action::String
end

struct PreflightReport
    julia::ObservedCheck
    git::ObservedCheck
    vscode::ObservedCheck
end

function default_command_probe(program, arguments)
    executable = Sys.which(program)
    isnothing(executable) && return (available=false, detail="$program was not found on PATH")

    stdout = IOBuffer()
    stderr = IOBuffer()
    command = Cmd([executable, arguments...])
    process = run(pipeline(ignorestatus(command), stdout=stdout, stderr=stderr))
    output = strip(join(filter(!isempty, [String(take!(stdout)), String(take!(stderr))]), '\n'))
    detail = isempty(output) ? "$program exited with code $(process.exitcode)" : output
    (available=process.exitcode == 0, detail=detail)
end

function collect_preflight(;
    version_probe=() -> VERSION,
    command_probe=default_command_probe,
)
    julia_version = version_probe()
    julia_check = ObservedCheck(
        :julia,
        julia_version == REQUIRED_JULIA_VERSION,
        string(julia_version),
        "Install and select Julia 1.12.6 with Juliaup, then run this check again.",
    )

    git_probe = command_probe("git", ["--version"])
    git_check = ObservedCheck(
        :git,
        git_probe.available,
        String(git_probe.detail),
        "Install Git and make sure the Git command is available on PATH.",
    )

    vscode_probe = command_probe("code", ["--version"])
    extension_probe = vscode_probe.available ?
        command_probe("code", ["--list-extensions"]) :
        (available=false, detail="VS Code is unavailable")
    extensions = lowercase.(strip.(split(String(extension_probe.detail), '\n')))
    has_julia_extension = extension_probe.available && "julialang.language-julia" in extensions
    vscode_passed = vscode_probe.available && has_julia_extension
    vscode_observed = if !vscode_probe.available
        String(vscode_probe.detail)
    elseif !extension_probe.available
        "$(first(split(String(vscode_probe.detail), '\n'))); extension list unavailable"
    elseif !has_julia_extension
        "$(first(split(String(vscode_probe.detail), '\n'))); Julia extension not found"
    else
        "$(first(split(String(vscode_probe.detail), '\n'))); julialang.language-julia installed"
    end
    vscode_action = vscode_probe.available ?
        "Install the Julia extension `julialang.language-julia` in VS Code, then run this check again." :
        "Install VS Code and enable its `code` command on PATH, then reopen the terminal."
    vscode_check = ObservedCheck(
        :vscode,
        vscode_passed,
        vscode_observed,
        vscode_action,
    )

    PreflightReport(julia_check, git_check, vscode_check)
end

function parse_preflight_arguments(arguments)
    github_confirmed = false
    agent = nothing
    index = 1
    while index <= length(arguments)
        argument = arguments[index]
        if argument == "--confirm-github"
            github_confirmed && throw(ArgumentError("--confirm-github may be specified only once"))
            github_confirmed = true
            index += 1
        elseif argument == "--confirm-agent"
            isnothing(agent) || throw(ArgumentError("--confirm-agent may be specified only once"))
            index == length(arguments) && throw(ArgumentError("--confirm-agent requires a product name"))
            candidate = arguments[index + 1]
            candidate in SUPPORTED_AGENTS || throw(ArgumentError(
                "unsupported Agent '$candidate'; choose copilot, codex, or amazon-q",
            ))
            agent = candidate
            index += 2
        else
            throw(ArgumentError("unknown preflight argument: $argument"))
        end
    end
    (; github_confirmed, agent)
end

function print_observed_check(io, label, check)
    status = check.passed ? "PASS" : "NEEDS SETUP"
    println(io, "  [$status] $label: $(check.observed)")
    check.passed || println(io, "    Action: $(check.action)")
end

function print_preflight(io, report; github_confirmed=false, agent=nothing)
    println(io, "Machine-observed checks")
    print_observed_check(io, "Julia", report.julia)
    print_observed_check(io, "Git", report.git)
    print_observed_check(io, "VS Code", report.vscode)
    println(io)
    println(io, "Manual confirmations")
    println(io, "  [$(github_confirmed ? "CONFIRMED" : "NOT CONFIRMED")] GitHub sign-in and repository access")
    agent_label = isnothing(agent) ? "none" : agent
    println(io, "  [$(isnothing(agent) ? "NOT CONFIRMED" : "CONFIRMED")] Supported Agent: $agent_label")
    nothing
end

function run_f00_preflight(
    root;
    report=collect_preflight(),
    github_confirmed=false,
    agent=nothing,
    persist_progress=save_progress,
    io=stdout,
)
    !isnothing(agent) && !(agent in SUPPORTED_AGENTS) &&
        throw(ArgumentError("unsupported Agent '$agent'"))
    print_preflight(io, report; github_confirmed, agent)

    observed_pass = report.julia.passed && report.git.passed && report.vscode.passed
    if !(observed_pass && github_confirmed && !isnothing(agent))
        println(io)
        println(io, "Progress was not updated. Complete every setup action and both manual confirmations.")
        return false
    end

    progress_path = joinpath(root, "course_progress.toml")
    state = load_progress(progress_path)
    if state.current == "F01" && state.completed == ["F00"]
        println(io)
        println(io, "F00 is complete; current exercise remains F01.")
        return true
    end
    state.current == "F00" && isempty(state.completed) || throw(ArgumentError(
        "F00 preflight can only update an initial F00 progress state",
    ))

    advanced = ProgressState(state.schema_version, state.ordered, ["F00"], "F01")
    persist_progress(progress_path, advanced)
    println(io)
    println(io, "F00 is complete. Current exercise is now F01; do not create an F00 branch or PR.")
    true
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    F00Environment.print_preflight(stdout, F00Environment.collect_preflight())
    println()
    println("This script is diagnostic only. Complete F00 through scripts/course.jl by following https://t2lab-it.github.io/thermofluid-exercise-2026/assignments/F00.html.")
end
