using Test

const FORMAT_SCRIPT = normpath(joinpath(@__DIR__, "..", "..", "scripts", "format.jl"))
include(FORMAT_SCRIPT)
using .CourseFormatting

contains_japanese_format_text(text::AbstractString) = occursin(r"[ぁ-んァ-ヶ一-龠]", text)

@testset "student Julia formatting boundary" begin
    mktempdir() do root
        write(joinpath(root, ".JuliaFormatter.toml"), """
        style = "default"
        indent = 4
        margin = 92
        always_for_in = true
        whitespace_ops_in_indices = true
        """)
        mkpath(joinpath(root, "exercises", "F00"))
        mkpath(joinpath(root, "test", "student"))
        mkpath(joinpath(root, "test", "provided"))
        mkpath(joinpath(root, "src"))

        editable = joinpath(root, "exercises", "F00", "run.jl")
        student_test = joinpath(root, "test", "student", "F00.jl")
        source_file = joinpath(root, "src", "Shared.jl")
        provided = joinpath(root, "test", "provided", "F00.jl")
        markdown = joinpath(root, "README.md")
        write(editable, "f(x)=x+1\n")
        write(student_test, "@test  f(1)==2\n")
        write(source_file, "g(x)=2x\n")
        write(provided, "@test  true\n")
        write(markdown, "do  not  format\n")

        before = Dict(path => read(path, String) for path in (
            editable, student_test, source_file, provided, markdown,
        ))
        diagnostics = IOBuffer()
        @test format_repository(root; check=true, io=diagnostics) == 1
        diagnostics_text = String(take!(diagnostics))
        @test contains_japanese_format_text(diagnostics_text)
        @test occursin("scripts/format.jl", diagnostics_text)
        @test all(read(path, String) == text for (path, text) in before)

        @test format_repository(root; check=false, io=IOBuffer()) == 0
        @test read(editable, String) == "f(x) = x+1\n"
        @test read(student_test, String) == "@test f(1)==2\n"
        @test read(source_file, String) == "g(x) = 2x\n"
        @test read(provided, String) == before[provided]
        @test read(markdown, String) == before[markdown]
        @test format_repository(root; check=true, io=IOBuffer()) == 0

        invalid = joinpath(root, "exercises", "F00", "invalid.jl")
        write(invalid, "function broken(\n")
        invalid_before = read(invalid, String)
        after_invalid = joinpath(root, "exercises", "F00", "zz_after_invalid.jl")
        write(after_invalid, "after_invalid(x)=x+1\n")

        diagnostics = IOBuffer()
        @test format_repository(root; check=true, io=diagnostics) == 1
        diagnostics_text = String(take!(diagnostics))
        @test contains_japanese_format_text(diagnostics_text)
        @test occursin("exercises/F00/invalid.jl", diagnostics_text)
        @test read(invalid, String) == invalid_before

        diagnostics = IOBuffer()
        @test format_repository(root; check=false, io=diagnostics) == 1
        diagnostics_text = String(take!(diagnostics))
        @test contains_japanese_format_text(diagnostics_text)
        @test occursin("exercises/F00/invalid.jl", diagnostics_text)
        @test read(invalid, String) == invalid_before
        @test read(after_invalid, String) == "after_invalid(x) = x+1\n"
    end
end
