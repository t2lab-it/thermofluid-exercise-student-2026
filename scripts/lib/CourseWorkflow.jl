module CourseWorkflow

using TOML

export ORDERED_UNITS, TASK_IDS_BY_UNIT, ProgressState, load_progress, save_progress,
       tests_to_run, validate_transition

const ORDERED_UNITS = [
    "F00", "F01", "F02", "F03", "F04",
    "N01", "N02", "N03", "N04", "N05-N06", "N07", "N08-N09",
]
const TASK_IDS_BY_UNIT = Dict(unit => [unit] for unit in ORDERED_UNITS)
TASK_IDS_BY_UNIT["N05-N06"] = ["N05", "N06"]
TASK_IDS_BY_UNIT["N08-N09"] = ["N08", "N09"]

const PROGRESS_KEYS = Set(["schema_version", "ordered", "completed", "current"])

struct ProgressState
    schema_version::Int
    ordered::Vector{String}
    completed::Vector{String}
    current::String
end

function _string_vector(value, field)
    value isa AbstractVector || throw(ArgumentError("$field must be an array of submission units"))
    all(item -> item isa AbstractString, value) ||
        throw(ArgumentError("$field must contain only string submission units"))
    String[String(item) for item in value]
end

function _validate(state::ProgressState)
    state.schema_version == 2 ||
        throw(ArgumentError("unsupported progress schema version: $(state.schema_version)"))
    state.ordered == ORDERED_UNITS ||
        throw(ArgumentError("ordered must contain every submission unit exactly once in course order"))
    length(unique(state.completed)) == length(state.completed) ||
        throw(ArgumentError("completed contains duplicate submission units"))
    state.current in state.ordered ||
        throw(ArgumentError("unknown current submission unit: $(state.current)"))
    state.current in state.completed &&
        throw(ArgumentError("current submission unit must not also be completed"))

    current_index = findfirst(==(state.current), state.ordered)
    expected_completed = state.ordered[1:(current_index - 1)]
    state.completed == expected_completed ||
        throw(ArgumentError("completed submission units must be the ordered prefix before current"))
    nothing
end

function load_progress(path)
    values = TOML.parsefile(path)
    Set(keys(values)) == PROGRESS_KEYS ||
        throw(ArgumentError("progress file must contain exactly: schema_version, ordered, completed, current"))

    schema_version = values["schema_version"]
    schema_version isa Integer && !(schema_version isa Bool) ||
        throw(ArgumentError("schema_version must be an integer"))
    current = values["current"]
    current isa AbstractString || throw(ArgumentError("current must be a string submission unit"))

    state = ProgressState(
        Int(schema_version),
        _string_vector(values["ordered"], "ordered"),
        _string_vector(values["completed"], "completed"),
        String(current),
    )
    _validate(state)
    state
end

function save_progress(path, state::ProgressState)
    _validate(state)
    directory = dirname(abspath(path))
    temporary_path, output = mktemp(directory; cleanup=false)
    try
        TOML.print(output, Dict(
            "schema_version" => state.schema_version,
            "ordered" => state.ordered,
            "completed" => state.completed,
            "current" => state.current,
        ); sorted=true)
        close(output)
        mv(temporary_path, path; force=true)
    finally
        isopen(output) && close(output)
        rm(temporary_path; force=true)
    end
    nothing
end

function tests_to_run(state::ProgressState)
    _validate(state)
    units = vcat(state.completed, [state.current])
    reduce(vcat, (TASK_IDS_BY_UNIT[unit] for unit in units); init=String[])
end

function validate_transition(state::ProgressState, id)
    _validate(state)
    current_index = findfirst(==(state.current), state.ordered)
    current_index == length(state.ordered) &&
        throw(ArgumentError("$(state.current) is the final submission unit"))
    expected = state.ordered[current_index + 1]
    id == expected ||
        throw(ArgumentError("next submission unit must be $expected, got $id"))
    nothing
end

end
