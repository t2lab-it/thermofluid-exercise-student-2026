using Test

const SELECTION_REPO_ROOT = normpath(joinpath(@__DIR__, "..", ".."))

function selection_command_result(command)
    stdout = IOBuffer()
    stderr = IOBuffer()
    process = run(pipeline(ignorestatus(command), stdout=stdout, stderr=stderr))
    (exitcode=process.exitcode, stdout=String(take!(stdout)), stderr=String(take!(stderr)))
end

if get(ENV, "COURSE_SELECTION_PROBE_CHILD", "0") != "1"
@testset "normal test entrypoint includes selected course tests" begin
    workflow_root = mktempdir()
    write(joinpath(workflow_root, "smoke_test.jl"), "using Test\n@test true\n")
    provided_root = mktempdir()
    write(joinpath(provided_root, "F00.jl"), "println(\"selected provided F00 marker\")\n")
    write(joinpath(provided_root, "F01.jl"), "error(\"future provided F01 marker loaded\")\n")
    student_root = mktempdir()
    write(joinpath(student_root, "F00.jl"), "println(\"selected student F00 marker\")\n")
    write(joinpath(student_root, "F01.jl"), "error(\"future student F01 marker loaded\")\n")

    runner = joinpath(SELECTION_REPO_ROOT, "test", "runtests.jl")
    command = Cmd(Cmd([
        Base.julia_cmd().exec...,
        "--startup-file=no",
        "--project=.",
        runner,
    ]); dir=SELECTION_REPO_ROOT)
    result = selection_command_result(addenv(
        command,
        "COURSE_WORKFLOW_TEST_ROOT" => workflow_root,
        "COURSE_SELECTION_PROBE_CHILD" => "1",
        "COURSE_PROVIDED_TEST_ROOT" => provided_root,
        "COURSE_STUDENT_TEST_ROOT" => student_root,
    ))
    @test result.exitcode == 0
    @test occursin("selected provided F00 marker", result.stdout)
    @test occursin("selected student F00 marker", result.stdout)
    @test !occursin("future provided F01 marker", result.stdout * result.stderr)
    @test !occursin("future student F01 marker", result.stdout * result.stderr)
end
end
