using Test

const CLI_REPO_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const COURSE_SCRIPT = joinpath(CLI_REPO_ROOT, "scripts", "course.jl")

include(joinpath(CLI_REPO_ROOT, "scripts", "lib", "CourseWorkflow.jl"))
using .CourseWorkflow

function command_result(command)
    stdout = IOBuffer()
    stderr = IOBuffer()
    process = run(pipeline(ignorestatus(command), stdout=stdout, stderr=stderr))
    (
        exitcode=process.exitcode,
        stdout=String(take!(stdout)),
        stderr=String(take!(stderr)),
    )
end

function write_task_test(path; passes=true)
    mkpath(dirname(path))
    open(path, "w") do output
        println(output, "using Test")
        println(output, passes ? "@test true" : "@test false")
    end
end

function git!(repo, arguments...)
    command = Cmd(`git -C $repo $(arguments)`; dir=repo)
    result = command_result(command)
    result.exitcode == 0 || error("git command failed: $(result.stderr)")
    result.stdout
end

function make_course_repo(; current="F01", failing_current=false)
    repo = mktempdir()
    mkpath(joinpath(repo, "scripts", "lib"))
    mkpath(joinpath(repo, "test", "tasks"))
    mkpath(joinpath(repo, "results"))
    cp(
        joinpath(CLI_REPO_ROOT, "scripts", "lib", "CourseWorkflow.jl"),
        joinpath(repo, "scripts", "lib", "CourseWorkflow.jl"),
    )
    cp(
        joinpath(CLI_REPO_ROOT, "scripts", "lib", "ResultLimits.jl"),
        joinpath(repo, "scripts", "lib", "ResultLimits.jl"),
    )
    cp(joinpath(CLI_REPO_ROOT, "test", "runtests.jl"), joinpath(repo, "test", "runtests.jl"))

    current_index = findfirst(==(current), ORDERED)
    state = ProgressState(1, ORDERED, ORDERED[1:(current_index - 1)], current)
    save_progress(joinpath(repo, "course_progress.toml"), state)
    for id in tests_to_run(state)
        write_task_test(
            joinpath(repo, "test", "tasks", "$(id)_test.jl");
            passes=!(failing_current && id == current),
        )
    end

    git!(repo, "init", "-b", "main")
    git!(repo, "config", "user.name", "Course CLI Test")
    git!(repo, "config", "user.email", "course-cli@example.invalid")
    git!(repo, "add", ".")
    git!(repo, "commit", "-m", "fixture")
    repo
end

function install_git_recorder()
    directory = mktempdir()
    bin = joinpath(directory, "bin")
    mkpath(bin)
    log = joinpath(directory, "git-commands")
    real_git = Sys.which("git")
    isnothing(real_git) && error("git is required for CLI tests")
    wrapper = joinpath(bin, "git")
    open(wrapper, "w") do output
        println(output, "#!/bin/sh")
        println(output, "printf 'git %s\\n' \"\u0024*\" >> \"\u0024COURSE_GIT_LOG\"")
        println(output, "case \"\u00241\" in pull|push|fetch) exit 97 ;; esac")
        println(output, "exec \"$real_git\" \"\u0024@\"")
    end
    chmod(wrapper, 0o755)
    (bin=bin, log=log)
end

function run_course(repo, arguments)
    recorder = install_git_recorder()
    command = `$(Base.julia_cmd()) --startup-file=no --project=$repo $COURSE_SCRIPT $(arguments)`
    command = Cmd(command; dir=repo)
    command = addenv(
        command,
        "PATH" => string(recorder.bin, Sys.iswindows() ? ';' : ':', ENV["PATH"]),
        "COURSE_GIT_LOG" => recorder.log,
    )
    result = command_result(command)
    executed_commands = isfile(recorder.log) ? read(recorder.log, String) : ""
    (; result..., executed_commands)
end

function progress_snapshot(repo)
    read(joinpath(repo, "course_progress.toml"), String)
end

@testset "local-only course CLI" begin
    @testset "course runner selects only current and completed IDs" begin
        command = `$(Base.julia_cmd()) --startup-file=no --project=$CLI_REPO_ROOT $(joinpath(CLI_REPO_ROOT, "test", "runtests.jl")) --course-only`
        result = command_result(addenv(command, "COURSE_TASK_TEST_ROOT" => joinpath(CLI_REPO_ROOT, "test", "fixtures", "git")))
        @test result.exitcode == 0
        @test occursin("loaded F00 fixture", result.stdout)
        @test !occursin("future F01 fixture", result.stderr)
    end

    @testset "start rejects an unclean working tree atomically" begin
        repo = make_course_repo()
        write(joinpath(repo, "student-note.txt"), "not committed")
        before = progress_snapshot(repo)
        result = run_course(repo, ["start", "F02"])
        @test result.exitcode != 0
        @test occursin("working tree", lowercase(result.stderr))
        @test progress_snapshot(repo) == before
        @test readchomp(`git -C $repo branch --show-current`) == "main"
    end

    @testset "start rejects a non-main branch atomically" begin
        repo = make_course_repo()
        git!(repo, "switch", "-c", "exercise/F01-foundations")
        before = progress_snapshot(repo)
        result = run_course(repo, ["start", "F02"])
        @test result.exitcode != 0
        @test occursin("main", result.stderr)
        @test progress_snapshot(repo) == before
    end

    @testset "start rejects a skipped ID atomically" begin
        repo = make_course_repo()
        before = progress_snapshot(repo)
        result = run_course(repo, ["start", "F03"])
        @test result.exitcode != 0
        @test occursin("F02", result.stderr)
        @test progress_snapshot(repo) == before
        @test readchomp(`git -C $repo branch --show-current`) == "main"
    end

    @testset "start rejects failing current tests atomically" begin
        repo = make_course_repo(failing_current=true)
        before = progress_snapshot(repo)
        result = run_course(repo, ["start", "F02"])
        @test result.exitcode != 0
        @test occursin("local tests failed", lowercase(result.stderr))
        @test progress_snapshot(repo) == before
        @test readchomp(`git -C $repo branch --show-current`) == "main"
    end

    @testset "start advances F01 to F02 on the exact local branch" begin
        repo = make_course_repo()
        result = run_course(repo, ["start", "F02"])
        @test result.exitcode == 0
        @test readchomp(`git -C $repo branch --show-current`) == "exercise/F02-julia-arrays-and-tests"
        state = load_progress(joinpath(repo, "course_progress.toml"))
        @test state.current == "F02"
        @test state.completed == ["F00", "F01"]
        @test occursin("git push", result.stdout)
        @test occursin("pull request", lowercase(result.stdout))
        @test !occursin(r"git (pull|push|fetch)", result.executed_commands)
    end

    @testset "help and other commands use portable local paths" begin
        repo = make_course_repo(current="F00")
        help_result = run_course(repo, ["--help"])
        @test help_result.exitcode == 0
        for command in ("preflight", "start <ID>", "status", "check-results")
            @test occursin(command, help_result.stdout)
        end
        @test occursin(joinpath("scripts", "course.jl"), help_result.stdout)
        @test !occursin("PowerShell", help_result.stdout)

        @test run_course(repo, ["preflight"]).exitcode == 0
        @test occursin("F00", run_course(repo, ["status"]).stdout)
        @test run_course(repo, ["check-results"]).exitcode == 0

        bad = run_course(repo, ["start"])
        @test bad.exitcode != 0
        @test occursin("start <ID>", bad.stderr)
        @test occursin(joinpath("scripts", "course.jl"), bad.stderr)
        @test !occursin("PowerShell", bad.stderr)
    end
end
