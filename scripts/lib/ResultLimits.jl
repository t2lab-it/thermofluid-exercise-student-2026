module ResultLimits

export FILE_LIMIT, TASK_LIMIT, TOTAL_LIMIT, check_result_limits

const FILE_LIMIT = 5 * 1024^2
const TASK_LIMIT = 10 * 1024^2
const TOTAL_LIMIT = 100 * 1024^2

function _files_under(path)
    files = String[]
    for (directory, _, names) in walkdir(path)
        append!(files, joinpath.(directory, names))
    end
    sort!(files)
end

function check_result_limits(
    root;
    file_limit=FILE_LIMIT,
    task_limit=TASK_LIMIT,
    total_limit=TOTAL_LIMIT,
)
    file_limit >= 0 || throw(ArgumentError("file_limit must be nonnegative"))
    task_limit >= 0 || throw(ArgumentError("task_limit must be nonnegative"))
    total_limit >= 0 || throw(ArgumentError("total_limit must be nonnegative"))
    isdir(root) || throw(ArgumentError("results root is not a directory: $root"))

    violations = String[]
    total_size = 0
    for entry in sort(readdir(root; join=true))
        if isdir(entry)
            task_size = 0
            for path in _files_under(entry)
                size = filesize(path)
                task_size += size
                total_size += size
                size > file_limit && push!(
                    violations,
                    "file limit exceeded: $(relpath(path, root)) is $size bytes (limit $file_limit bytes)",
                )
            end
            task_size > task_limit && push!(
                violations,
                "task limit exceeded: $(relpath(entry, root)) is $task_size bytes (limit $task_limit bytes)",
            )
        elseif isfile(entry)
            size = filesize(entry)
            total_size += size
            size > file_limit && push!(
                violations,
                "file limit exceeded: $(relpath(entry, root)) is $size bytes (limit $file_limit bytes)",
            )
        end
    end

    total_size > total_limit && push!(
        violations,
        "results limit exceeded: results total is $total_size bytes (limit $total_limit bytes)",
    )
    violations
end

end
