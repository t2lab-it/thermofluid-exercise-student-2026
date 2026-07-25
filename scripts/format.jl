module CourseFormatting

using JuliaFormatter

export format_repository, main, student_julia_files

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, ".."))
const EDITABLE_ROOTS = (
    joinpath("exercises"),
    joinpath("test", "student"),
    joinpath("src"),
)

function student_julia_files(root=REPOSITORY_ROOT)
    files = String[]
    for relative in EDITABLE_ROOTS
        directory = joinpath(root, relative)
        isdir(directory) || continue
        for (current, directories, names) in walkdir(directory)
            sort!(directories)
            for name in sort(names)
                endswith(name, ".jl") && push!(files, joinpath(current, name))
            end
        end
    end
    sort!(files)
end

function format_repository(root=REPOSITORY_ROOT; check=false, io=stdout)
    files = student_julia_files(root)
    if check
        unformatted = filter(
            path -> !JuliaFormatter.format(path; overwrite=false),
            files,
        )
        isempty(unformatted) && return 0
        println(io, "Julia code is not formatted:")
        foreach(path -> println(io, "  ", relpath(path, root)), unformatted)
        println(io, "\nRun:\n  julia --project=. scripts/format.jl")
        return 1
    end
    foreach(path -> JuliaFormatter.format(path; overwrite=true), files)
    return 0
end

function main(arguments=ARGS)
    arguments == String[] && return format_repository()
    arguments == ["--check"] && return format_repository(; check=true)
    println(stderr, "usage: julia --project=. scripts/format.jl [--check]")
    return 2
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    exit(CourseFormatting.main())
end
