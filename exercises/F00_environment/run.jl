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
    isnothing(executable) &&
        return (available = false, detail = "$(program)がPATH上に見つかりません")

    stdout = IOBuffer()
    stderr = IOBuffer()
    command = Cmd([executable, arguments...])
    process = run(pipeline(ignorestatus(command), stdout = stdout, stderr = stderr))
    output =
        strip(join(filter(!isempty, [String(take!(stdout)), String(take!(stderr))]), '\n'))
    detail = isempty(output) ? "$(program)の終了コード: $(process.exitcode)" : output
    (available = process.exitcode == 0, detail = detail)
end

function collect_preflight(;
    version_probe = () -> VERSION,
    command_probe = default_command_probe,
)
    julia_version = version_probe()
    julia_check = ObservedCheck(
        :julia,
        julia_version == REQUIRED_JULIA_VERSION,
        string(julia_version),
        "JuliaupでJulia 1.12.6をインストールして選択し、この確認を再実行してください。",
    )

    git_probe = command_probe("git", ["--version"])
    git_check = ObservedCheck(
        :git,
        git_probe.available,
        String(git_probe.detail),
        "Gitをインストールし、GitコマンドをPATHから実行できることを確認してください。",
    )

    vscode_probe = command_probe("code", ["--version"])
    extension_probe =
        vscode_probe.available ? command_probe("code", ["--list-extensions"]) :
        (available = false, detail = "VS Codeを利用できません")
    extensions = lowercase.(strip.(split(String(extension_probe.detail), '\n')))
    has_julia_extension =
        extension_probe.available && "julialang.language-julia" in extensions
    vscode_passed = vscode_probe.available && has_julia_extension
    vscode_observed = if !vscode_probe.available
        String(vscode_probe.detail)
    elseif !extension_probe.available
        "$(first(split(String(vscode_probe.detail), '\n'))); 拡張機能一覧を取得できません"
    elseif !has_julia_extension
        "$(first(split(String(vscode_probe.detail), '\n'))); Julia拡張機能が見つかりません"
    else
        "$(first(split(String(vscode_probe.detail), '\n'))); julialang.language-juliaを導入済みです"
    end
    vscode_action =
        vscode_probe.available ?
        "VS CodeへJulia拡張機能`julialang.language-julia`をインストールし、この確認を再実行してください。" :
        "VS Codeをインストールして`code`コマンドをPATHで有効にし、端末を開き直してください。"
    vscode_check = ObservedCheck(:vscode, vscode_passed, vscode_observed, vscode_action)

    PreflightReport(julia_check, git_check, vscode_check)
end

function parse_preflight_arguments(arguments)
    github_confirmed = false
    agent = nothing
    index = 1
    while index <= length(arguments)
        argument = arguments[index]
        if argument == "--confirm-github"
            github_confirmed &&
                throw(ArgumentError("--confirm-githubは1回だけ指定できます"))
            github_confirmed = true
            index += 1
        elseif argument == "--confirm-agent"
            isnothing(agent) ||
                throw(ArgumentError("--confirm-agentは1回だけ指定できます"))
            index == length(arguments) &&
                throw(ArgumentError("--confirm-agentには製品名が必要です"))
            candidate = arguments[index + 1]
            candidate in SUPPORTED_AGENTS || throw(
                ArgumentError(
                    "未対応のAIエージェント`$candidate`です。copilot、codex、amazon-qから選んでください",
                ),
            )
            agent = candidate
            index += 2
        else
            throw(ArgumentError("`preflight`の不明な引数です: $argument"))
        end
    end
    (; github_confirmed, agent)
end

function print_observed_check(io, label, check)
    status = check.passed ? "PASS" : "NEEDS SETUP"
    println(io, "  [$status] $label: $(check.observed)")
    check.passed || println(io, "    対応: $(check.action)")
end

function print_preflight(io, report; github_confirmed = false, agent = nothing)
    println(io, "端末で確認した項目")
    print_observed_check(io, "Julia", report.julia)
    print_observed_check(io, "Git", report.git)
    print_observed_check(io, "VS Code", report.vscode)
    println(io)
    println(io, "手動確認")
    println(
        io,
        "  [$(github_confirmed ? "CONFIRMED" : "NOT CONFIRMED")] GitHubへのサインインとリポジトリへのアクセス",
    )
    agent_label = isnothing(agent) ? "未指定" : agent
    println(
        io,
        "  [$(isnothing(agent) ? "NOT CONFIRMED" : "CONFIRMED")] 正式対応AIエージェント: $agent_label",
    )
    nothing
end

function run_f00_preflight(
    root;
    report = collect_preflight(),
    github_confirmed = false,
    agent = nothing,
    persist_progress = save_progress,
    io = stdout,
)
    !isnothing(agent) &&
        !(agent in SUPPORTED_AGENTS) &&
        throw(ArgumentError("未対応のAIエージェント`$agent`です"))
    print_preflight(io, report; github_confirmed, agent)

    observed_pass = report.julia.passed && report.git.passed && report.vscode.passed
    if !(observed_pass && github_confirmed && !isnothing(agent))
        println(io)
        println(
            io,
            "F00の進捗は更新されませんでした。すべての対応と2項目の手動確認を完了してください。",
        )
        return false
    end

    progress_path = joinpath(root, "course_progress.toml")
    state = load_progress(progress_path)
    if state.current == "F01" && state.completed == ["F00"]
        println(io)
        println(io, "F00は完了済みです。現在の課題はF01のままです。")
        return true
    end
    state.current == "F00" && isempty(state.completed) ||
        throw(ArgumentError("F00の事前診断は初期F00進捗だけを更新できます"))

    advanced = ProgressState(state.schema_version, state.ordered, ["F00"], "F01")
    persist_progress(progress_path, advanced)
    println(io)
    println(
        io,
        "F00が完了しました。現在の課題はF01です。F00用のbranchやPRは作成しないでください。",
    )
    true
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    F00Environment.print_preflight(stdout, F00Environment.collect_preflight())
    println()
    println(
        "このスクリプトは診断専用です。https://t2lab-it.github.io/thermofluid-exercise-2026/assignments/F00.html に従い、scripts/course.jlからF00を完了してください。",
    )
end
