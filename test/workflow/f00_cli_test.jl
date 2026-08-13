using Test

const F00_CLI_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
include(joinpath(F00_CLI_ROOT, "scripts", "course.jl"))

contains_japanese(text::AbstractString) = occursin(r"[ぁ-んァ-ヶ一-龠]", text)

function passing_preflight_report()
    PreflightReport(
        ObservedCheck(:julia, true, "1.12.6", ""),
        ObservedCheck(:git, true, "git version test", ""),
        ObservedCheck(:vscode, true, "VS Code test", ""),
    )
end

function failing_preflight_report()
    PreflightReport(
        ObservedCheck(:julia, true, "1.12.6", ""),
        ObservedCheck(:git, false, "git not found", "Install Git"),
        ObservedCheck(:vscode, false, "code not found", "Install VS Code"),
    )
end

function f00_command_result(command)
    stdout = IOBuffer()
    stderr = IOBuffer()
    process = run(pipeline(ignorestatus(command), stdout=stdout, stderr=stderr))
    (
        exitcode=process.exitcode,
        stdout=String(take!(stdout)),
        stderr=String(take!(stderr)),
    )
end

function f00_cli_root()
    root = mktempdir()
    save_progress(
        joinpath(root, "course_progress.toml"),
        ProgressState(2, ORDERED_UNITS, String[], "F00"),
    )
    root
end

@testset "F00 course CLI wiring" begin
    root = f00_cli_root()
    writes = Ref(0)
    persist = function (path, state)
        writes[] += 1
        save_progress(path, state)
    end

    output = IOBuffer()
    @test main(
        ["preflight"];
        root,
        preflight_report=passing_preflight_report(),
        persist_progress=persist,
        io=output,
    ) == 0
    @test writes[] == 0
    @test load_progress(joinpath(root, "course_progress.toml")).current == "F00"

    @test main(
        ["preflight", "--confirm-github"];
        root,
        preflight_report=passing_preflight_report(),
        persist_progress=persist,
        io=IOBuffer(),
    ) != 0
    @test writes[] == 0
    @test load_progress(joinpath(root, "course_progress.toml")).current == "F00"

    @test main(
        ["preflight", "--confirm-github", "--confirm-agent", "codex"];
        root,
        preflight_report=failing_preflight_report(),
        persist_progress=persist,
        io=IOBuffer(),
    ) != 0
    @test writes[] == 0
    @test load_progress(joinpath(root, "course_progress.toml")).current == "F00"

    output = IOBuffer()
    @test main(
        ["preflight", "--confirm-github", "--confirm-agent", "codex"];
        root,
        preflight_report=passing_preflight_report(),
        persist_progress=persist,
        io=output,
    ) == 0
    @test writes[] == 1
    @test load_progress(joinpath(root, "course_progress.toml")).current == "F01"
    text = String(take!(output))
    @test contains_japanese(text)
    for identifier in ("Julia", "Git", "VS Code", "F00", "F01")
        @test occursin(identifier, text)
    end

    @test_throws ArgumentError main(
        ["preflight", "--confirm-agent", "copilot", "--confirm-agent", "codex"];
        root,
        preflight_report=passing_preflight_report(),
        io=IOBuffer(),
    )

    @testset "machine probes are lazy and preflight-only" begin
        lazy_root = f00_cli_root()
        calls = Ref(0)
        collector = function ()
            calls[] += 1
            passing_preflight_report()
        end

        @test main(["status"]; root=lazy_root, preflight_collector=collector) == 0
        @test calls[] == 0

        @test main(
            ["preflight"];
            root=lazy_root,
            preflight_collector=collector,
            io=IOBuffer(),
        ) == 0
        @test calls[] == 1
    end

    @testset "real process rejects a confirmed completion attempt when probes fail" begin
        process_root = f00_cli_root()
        progress_path = joinpath(process_root, "course_progress.toml")
        before = read(progress_path, String)
        empty_path = mktempdir()
        command = Cmd(Cmd([
            Base.julia_cmd().exec...,
            "--startup-file=no",
            "--project=$F00_CLI_ROOT",
            joinpath(F00_CLI_ROOT, "scripts", "course.jl"),
            "preflight",
            "--confirm-github",
            "--confirm-agent",
            "codex",
        ]); dir=process_root)
        result = f00_command_result(addenv(command, "PATH" => empty_path))
        @test result.exitcode != 0
        @test contains_japanese(result.stdout)
        @test occursin("NEEDS SETUP", result.stdout)
        @test occursin("F00", result.stdout)
        @test read(progress_path, String) == before
    end
end
