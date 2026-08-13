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
    file_limit >= 0 || throw(ArgumentError("`file_limit`は0以上にしてください"))
    task_limit >= 0 || throw(ArgumentError("`task_limit`は0以上にしてください"))
    total_limit >= 0 || throw(ArgumentError("`total_limit`は0以上にしてください"))
    isdir(root) || throw(ArgumentError("`results`ルートがディレクトリではありません: $root"))

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
                    "ファイル上限を超えました: $(relpath(path, root))は$(size)バイトです（上限$(file_limit)バイト）",
                )
            end
            task_size > task_limit && push!(
                violations,
                "課題上限を超えました: $(relpath(entry, root))は$(task_size)バイトです（上限$(task_limit)バイト）",
            )
        elseif isfile(entry)
            size = filesize(entry)
            total_size += size
            size > file_limit && push!(
                violations,
                "ファイル上限を超えました: $(relpath(entry, root))は$(size)バイトです（上限$(file_limit)バイト）",
            )
        end
    end

    total_size > total_limit && push!(
        violations,
        "成果物全体の上限を超えました: `results`の合計は$(total_size)バイトです（上限$(total_limit)バイト）",
    )
    violations
end

end
