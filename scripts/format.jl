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

function format_file(path, root; overwrite, io)
    try
        JuliaFormatter.format(path; overwrite, throw_on_error=true)
    catch error
        println(
            io,
            "Julia formatting failed for ",
            relpath(path, root),
            ": ",
            sprint(showerror, error),
        )
        nothing
    end
end

function format_repository(root=REPOSITORY_ROOT; check=false, io=stdout)
    files = student_julia_files(root)
    if check
        unformatted = String[]
        failed = false
        for path in files
            result = format_file(path, root; overwrite=false, io)
            if isnothing(result)
                failed = true
            elseif !result
                push!(unformatted, path)
            end
        end
        if !isempty(unformatted)
            println(io, "Julia code is not formatted:")
            foreach(path -> println(io, "  ", relpath(path, root)), unformatted)
            println(io, "\nRun:\n  julia --project=. scripts/format.jl")
        end
        return failed || !isempty(unformatted) ? 1 : 0
    end
    failed = false
    for path in files
        isnothing(format_file(path, root; overwrite=true, io)) && (failed = true)
    end
    return failed ? 1 : 0
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
