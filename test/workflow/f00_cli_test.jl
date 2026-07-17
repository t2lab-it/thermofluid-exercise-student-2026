using Test

const F00_CLI_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
include(joinpath(F00_CLI_ROOT, "scripts", "course.jl"))

function passing_preflight_report()
    PreflightReport(
        ObservedCheck(:julia, true, "1.12.6", ""),
        ObservedCheck(:git, true, "git version test", ""),
        ObservedCheck(:vscode, true, "VS Code test", ""),
    )
end

function f00_cli_root()
    root = mktempdir()
    save_progress(
        joinpath(root, "course_progress.toml"),
        ProgressState(1, ORDERED, String[], "F00"),
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
    @test occursin("Machine-observed checks", text)
    @test occursin("Manual confirmations", text)

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
end
