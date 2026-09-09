using Test
using ThermofluidExercise

isempty(ARGS) || error("使い方: julia --project=. -e 'using Pkg; Pkg.test()'")
const REPO_ROOT = normpath(joinpath(@__DIR__, ".."))
include(joinpath(REPO_ROOT, "scripts", "lib", "CourseWorkflow.jl"))
include(joinpath(REPO_ROOT, "scripts", "lib", "ResultLimits.jl"))
using .CourseWorkflow
using .ResultLimits

state = load_progress(joinpath(REPO_ROOT, "course_progress.toml"))
for unit in units_to_test(state)
    for name in ("provided_tests.jl", "tests.jl")
        path = joinpath(REPO_ROOT, unit_directory(unit), name)
        isfile(path) || error("$unit の必須テストがありません: $path")
        @testset "$unit / $name" begin
            include(path)
        end
    end
end
violations = check_result_limits(REPO_ROOT)
isempty(violations) || error(join(violations, '\n'))
