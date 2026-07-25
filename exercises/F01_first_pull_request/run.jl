module F01FirstPullRequest

export main, student_greeting

"""
    student_greeting(name::AbstractString) -> String

Return `"Hello, <name>!"` after removing whitespace around `name`.
Blank names are invalid. Complete the marked return statement for F01.
"""
function student_greeting(name::AbstractString)::String
    normalized_name = strip(name)
    isempty(normalized_name) && throw(ArgumentError("name must not be blank"))

    # TODO(F01): replace this placeholder with `Hello, <normalized_name>!`.
    "TODO: implement student_greeting"
end

function main(name::AbstractString = "student"; io = stdout)
    message = student_greeting(name)
    println(io, message)
    message
end

end


if abspath(PROGRAM_FILE) == @__FILE__
    name = isempty(ARGS) ? "student" : only(ARGS)
    F01FirstPullRequest.main(name)
end
