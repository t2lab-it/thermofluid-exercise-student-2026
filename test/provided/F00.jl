using Test

const F00_REPO_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const F00_RUN_SCRIPT = joinpath(F00_REPO_ROOT, "exercises", "F00_environment", "run.jl")

if !isdefined(Main, :F00Environment)
    include(F00_RUN_SCRIPT)
end
if !isdefined(Main, :CourseWorkflow)
    include(joinpath(F00_REPO_ROOT, "scripts", "lib", "CourseWorkflow.jl"))
end

using .F00Environment
using .CourseWorkflow

function f00_report(; julia_ok=true, git_ok=true, vscode_ok=true, julia_extension_ok=true)
    versions = () -> julia_ok ? v"1.12.6" : v"1.12.5"
    commands = function (program, arguments)
        if program == "git"
            return (available=git_ok, detail=git_ok ? "git version test" : "git not found")
        elseif program == "code"
            if arguments == ["--list-extensions"]
                extensions = julia_extension_ok ? "JULIALANG.LANGUAGE-JULIA\nother.extension" : "other.extension"
                return (available=vscode_ok, detail=vscode_ok ? extensions : "code not found")
            end
            return (available=vscode_ok, detail=vscode_ok ? "1.99.0" : "code not found")
        end
        error("unexpected command probe: $program $(join(arguments, ' '))")
    end
    collect_preflight(; version_probe=versions, command_probe=commands)
end

function initial_f00_repo()
    root = mktempdir()
    state = ProgressState(1, ORDERED, String[], "F00")
    save_progress(joinpath(root, "course_progress.toml"), state)
    root
end

@testset "F00 environment preflight" begin
    @testset "machine-observed checks are structured and exact" begin
        report = f00_report()
        @test report.julia.id == :julia
        @test report.julia.passed
        @test report.julia.observed == "1.12.6"
        @test report.git.id == :git
        @test report.git.passed
        @test report.vscode.id == :vscode
        @test report.vscode.passed

        wrong_patch = f00_report(julia_ok=false)
        @test !wrong_patch.julia.passed
        @test occursin("1.12.6", wrong_patch.julia.action)

        missing_git = f00_report(git_ok=false)
        @test !missing_git.git.passed
        @test occursin("Git", missing_git.git.action)

        missing_vscode = f00_report(vscode_ok=false)
        @test !missing_vscode.vscode.passed
        @test occursin("VS Code", missing_vscode.vscode.action)
        @test occursin("code", lowercase(missing_vscode.vscode.action))

        missing_extension = f00_report(julia_extension_ok=false)
        @test !missing_extension.vscode.passed
        @test occursin("Julia extension", missing_extension.vscode.action)
        @test occursin("julialang.language-julia", lowercase(missing_extension.vscode.action))
    end

    @testset "manual confirmations are explicit and unambiguous" begin
        @test parse_preflight_arguments(String[]) == (github_confirmed=false, agent=nothing)
        @test parse_preflight_arguments(["--confirm-github", "--confirm-agent", "copilot"]) ==
            (github_confirmed=true, agent="copilot")
        @test parse_preflight_arguments(["--confirm-agent", "codex", "--confirm-github"]) ==
            (github_confirmed=true, agent="codex")
        @test parse_preflight_arguments(["--confirm-github", "--confirm-agent", "amazon-q"]) ==
            (github_confirmed=true, agent="amazon-q")
        @test_throws ArgumentError parse_preflight_arguments(["--confirm-agent", "claude"])
        @test_throws ArgumentError parse_preflight_arguments([
            "--confirm-agent", "copilot", "--confirm-agent", "codex",
        ])
        @test_throws ArgumentError parse_preflight_arguments(["--confirm-github", "--confirm-github"])
        @test_throws ArgumentError parse_preflight_arguments(["--unknown"])
    end

    @testset "progress changes only after observed and manual gates pass" begin
        root = initial_f00_repo()
        progress_path = joinpath(root, "course_progress.toml")
        before = read(progress_path, String)

        output = IOBuffer()
        @test !run_f00_preflight(root; report=f00_report(), io=output)
        @test read(progress_path, String) == before
        text = String(take!(output))
        @test occursin("Machine-observed checks", text)
        @test occursin("Manual confirmations", text)
        @test occursin("Progress was not updated", text)

        output = IOBuffer()
        @test !run_f00_preflight(
            root;
            report=f00_report(),
            github_confirmed=true,
            io=output,
        )
        @test read(progress_path, String) == before

        for failed_report in (f00_report(julia_ok=false), f00_report(git_ok=false), f00_report(vscode_ok=false))
            output = IOBuffer()
            @test !run_f00_preflight(
                root;
                report=failed_report,
                github_confirmed=true,
                agent="codex",
                io=output,
            )
            @test read(progress_path, String) == before
        end

        output = IOBuffer()
        @test run_f00_preflight(
            root;
            report=f00_report(),
            github_confirmed=true,
            agent="codex",
            io=output,
        )
        state = load_progress(progress_path)
        @test state.completed == ["F00"]
        @test state.current == "F01"
        @test occursin("F00 is complete", String(take!(output)))
    end

    @testset "completion is atomic and idempotent without Git side effects" begin
        root = initial_f00_repo()
        progress_path = joinpath(root, "course_progress.toml")
        before = read(progress_path, String)
        writes = Ref(0)
        failing_persistence = function (path, state)
            writes[] += 1
            error("injected persistence failure")
        end
        @test_throws ErrorException run_f00_preflight(
            root;
            report=f00_report(),
            github_confirmed=true,
            agent="copilot",
            persist_progress=failing_persistence,
            io=IOBuffer(),
        )
        @test writes[] == 1
        @test read(progress_path, String) == before

        @test run_f00_preflight(
            root;
            report=f00_report(),
            github_confirmed=true,
            agent="copilot",
            io=IOBuffer(),
        )
        after = read(progress_path, String)
        writes[] = 0
        @test run_f00_preflight(
            root;
            report=f00_report(),
            github_confirmed=true,
            agent="amazon-q",
            persist_progress=(path, state) -> (writes[] += 1),
            io=IOBuffer(),
        )
        @test writes[] == 0
        @test read(progress_path, String) == after
        @test !isdir(joinpath(root, "learning_logs"))
        @test !isdir(joinpath(root, ".git"))
    end

    @testset "student-facing F00 files keep the bounded contract" begin
        task_path = joinpath(F00_REPO_ROOT, "exercises", "F00_environment", "TASK.md")
        @test isfile(task_path)
        @test isfile(F00_RUN_SCRIPT)
        if isfile(task_path)
            task = read(task_path, String)
            @test occursin("assignments/F00", task)
            @test occursin("--confirm-github", task)
            @test occursin("--confirm-agent", task)
            @test occursin("juliaup", lowercase(task))
            @test occursin("Julia拡張", task)
            @test occursin("Pkg.instantiate", task)
            @test occursin("秘密", task)
            @test !occursin("Codespaces", task)
            @test !occursin("devcontainer", lowercase(task))
        end
    end
end
