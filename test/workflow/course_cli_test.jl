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

function install_git_recorder(; windows=Sys.iswindows())
    directory = mktempdir()
    bin = joinpath(directory, "bin")
    mkpath(bin)
    log = joinpath(directory, "git-commands")
    real_git = Sys.which("git")
    isnothing(real_git) && error("git is required for CLI tests")
    prohibited = "pull push fetch clone remote merge"

    if windows
        wrapper = joinpath(bin, "git.cmd")
        open(wrapper, "w") do output
            println(output, "@echo off")
            println(output, ">>\"%COURSE_GIT_LOG%\" echo git %*")
            println(output, "for %%A in (%*) do for %%V in ($prohibited) do if /I \"%%~A\"==\"%%V\" exit /b 97")
            println(output, "\"$real_git\" %*")
            println(output, "exit /b %ERRORLEVEL%")
        end
    else
        wrapper = joinpath(bin, "git")
        open(wrapper, "w") do output
            println(output, "#!/bin/sh")
            println(output, "printf 'git %s\\n' \"\u0024*\" >> \"\u0024COURSE_GIT_LOG\"")
            println(output, "for argument in \"\u0024@\"; do")
            println(output, "  case \"\u0024argument\" in pull|push|fetch|clone|remote|merge) exit 97 ;; esac")
            println(output, "done")
            println(output, "exec \"$real_git\" \"\u0024@\"")
        end
        chmod(wrapper, 0o755)
    end
    (bin=bin, log=log, wrapper=wrapper)
end

select_native_recorder(unix_recorder, windows_recorder; windows=Sys.iswindows()) =
    windows ? windows_recorder : unix_recorder

function recorder_command(recorder, arguments; windows=Sys.iswindows())
    if windows
        return Cmd(["cmd.exe", "/c", recorder.wrapper, arguments...])
    end
    Cmd([recorder.wrapper, arguments...])
end

function run_course(repo, arguments)
    recorder = install_git_recorder()
    command = `$(Base.julia_cmd()) --startup-file=no --project=$repo $COURSE_SCRIPT $(arguments)`
    command = Cmd(command; dir=repo)
    command = addenv(
        command,
        "PATH" => string(recorder.bin, Sys.iswindows() ? ';' : ':', ENV["PATH"]),
        "COURSE_GIT_LOG" => recorder.log,
        "COURSE_TASK_TEST_ROOT" => joinpath(repo, "test", "tasks"),
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
if get(ENV, "COURSE_SELECTION_PROBE_CHILD", "0") != "1"
@testset "Task 3 review regressions" begin
    @testset "student README uses public assignment pages" begin
        readme = read(joinpath(CLI_REPO_ROOT, "README.md"), String)
        @test !occursin("TASK.md", readme)
        @test occursin("https://t2lab-it.github.io/thermofluid-exercise-2026/", readme)
        @test occursin("run.jl", readme)
    end
    @testset "Git recorder is cross-platform and rejects automated history or network verbs" begin
        unix_recorder = try
            install_git_recorder(windows=false)
        catch exception
            nothing
        end
        windows_recorder = try
            install_git_recorder(windows=true)
        catch exception
            nothing
        end
        @test !isnothing(unix_recorder)
        @test !isnothing(windows_recorder)
        if !isnothing(unix_recorder) && !isnothing(windows_recorder)
            selected_unix = try
                select_native_recorder(unix_recorder, windows_recorder; windows=false)
            catch
                nothing
            end
            selected_windows = try
                select_native_recorder(unix_recorder, windows_recorder; windows=true)
            catch
                nothing
            end
            @test !isnothing(selected_unix)
            @test !isnothing(selected_windows)
            if !isnothing(selected_unix) && !isnothing(selected_windows)
                @test selected_unix.wrapper == unix_recorder.wrapper
                @test selected_windows.wrapper == windows_recorder.wrapper
                unix_command = recorder_command(selected_unix, ["-C", "repo", "merge"]; windows=false)
                windows_command = recorder_command(selected_windows, ["-C", "repo", "merge"]; windows=true)
                @test first(unix_command.exec) == unix_recorder.wrapper
                @test lowercase(basename(first(windows_command.exec))) in ("cmd", "cmd.exe")
                @test "/c" in lowercase.(windows_command.exec)
            end
            @test endswith(unix_recorder.wrapper, "git")
            @test endswith(windows_recorder.wrapper, "git.cmd")
            native_recorder = select_native_recorder(unix_recorder, windows_recorder)
            for verb in ("pull", "push", "fetch", "clone", "remote", "merge")
                command = recorder_command(native_recorder, ["-C", make_course_repo(), verb])
                result = command_result(addenv(command, "COURSE_GIT_LOG" => native_recorder.log))
                @test result.exitcode == 97
                @test occursin("git ", read(native_recorder.log, String))
                @test occursin(verb, read(native_recorder.log, String))
            end
        end
    end

    @testset "start rolls back its branch when progress persistence fails" begin
        repo = make_course_repo()
        before = progress_snapshot(repo)
        probe = """
        course_script = $(repr(COURSE_SCRIPT))
        root = ARGS[1]
        source = read(course_script, String)
        guarded = occursin("abspath(PROGRAM_FILE)", source)
        if guarded
            include(course_script)
        else
            entrypoint = findfirst("\\ntry\\n    exit(main())", source)
            include_string(Main, source[begin:(first(entrypoint) - 1)], course_script)
            @eval CourseWorkflow save_progress(path::AbstractString, state::ProgressState) =
                error("injected persistence failure")
        end
        try
            if guarded
                start_exercise(root, "F02"; persist_progress=(path, state) -> error("injected persistence failure"))
            else
                start_exercise(root, "F02")
            end
        catch exception
            println("caught: ", sprint(showerror, exception))
        end
        println("rollback probe complete")
        """
        command = Cmd(Cmd([
            Base.julia_cmd().exec...,
            "--startup-file=no",
            "--project=$repo",
            "-e",
            probe,
            repo,
        ]); dir=repo)
        command = addenv(command, "COURSE_TASK_TEST_ROOT" => joinpath(repo, "test", "tasks"))
        result = command_result(command)
        @test result.exitcode == 0
        @test occursin("injected persistence failure", result.stdout)
        @test occursin("rollback probe complete", result.stdout)
        @test readchomp(`git -C $repo branch --show-current`) == "main"
        branches = read(Cmd(["git", "-C", repo, "branch", "--format=%(refname:short)"]), String)
        @test !occursin("exercise/F02-julia-arrays-and-tests", branches)
        @test progress_snapshot(repo) == before
    end
end
end
