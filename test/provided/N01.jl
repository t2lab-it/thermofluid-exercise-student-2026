using Test
using TOML

const N01_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const N01_RUN = joinpath(N01_ROOT, "exercises", "N01_linear_advection", "run.jl")
const N01_SUPPORT = joinpath(
    N01_ROOT, "exercises", "N01_linear_advection", "provided_support.jl",
)
const N01_LOG = joinpath(N01_ROOT, "learning_logs", "templates", "N01.md")
const N01_STUDENT_TEST = joinpath(N01_ROOT, "test", "student", "N01.jl")
function n01_test_assertions(node, assertions=Any[])
    node isa Expr || return assertions
    node.head in (:quote, :inert, :function, :macro, :->) && return assertions
    if node.head == :macrocall && length(node.args) >= 3 && first(node.args) == Symbol("@test")
        push!(assertions, node.args[3])
        return assertions
    end
    foreach(child -> n01_test_assertions(child, assertions), node.args)
    return assertions
end

function n01_student_test_state(source)
    parsed = try
        Meta.parseall(source)
    catch
        return (; is_scaffold=false, is_completed=false)
    end
    assertions = n01_test_assertions(parsed)
    marker = occursin("STUDENT_TEST_REQUIRED(N01)", source)
    has_literal_false = any(assertion -> assertion === false, assertions)
    has_nontrivial_test = any(assertion -> assertion !== false && assertion !== true, assertions)
    return (
        is_scaffold=marker && has_literal_false,
        is_completed=!marker && !has_literal_false && has_nontrivial_test,
    )
end

@testset "N01 self-contained linear advection" begin
    @testset "student test completion marker" begin
        scaffold = n01_student_test_state("""
            # STUDENT_TEST_REQUIRED(N01): student-owned placeholder
            @test false
        """)
        @test scaffold.is_scaffold
        @test !scaffold.is_completed

        literal_true = n01_student_test_state("@test true")
        @test !literal_true.is_scaffold
        @test !literal_true.is_completed

        completed = n01_student_test_state("""
            result = N01LinearAdvection.simulate(; scheme=:upwind)
            @test result.minimum == 1.0
        """)
        @test !completed.is_scaffold
        @test completed.is_completed

        quoted = n01_student_test_state("""
            quote
                @test result.minimum == 1.0
            end
        """)
        @test !quoted.is_completed
    end

    @test isfile(N01_RUN)
    if isfile(N01_RUN)
        source = read(N01_RUN, String)
        @test !occursin("ThermofluidExercise", source)
        @test !occursin("Vector{Vector", source)
        section_markers = (
            "# === 学生が実装する3つの関数 ===",
            "# === 境界条件と時間発展の流れ ===",
        )
        marker_positions = map(marker -> findfirst(marker, source), section_markers)
        @test all(!isnothing, marker_positions)
        if all(!isnothing, marker_positions)
            @test issorted(map(first, marker_positions))
        end

        for required_header in (
            "1次元線形移流方程式",
            "読む順序",
            "rectangular_initial_condition → upwind_step! / centered_step!",
            "apply_boundary! → simulate → main",
            "provided_support.jl",
            "入力検証と出力の詳細",
            "おまじない",
            "読解・編集する必要はありません",
            "value::T",
            "{<:Real}",
            ":upwind",
            "condition ? true_value : false_value",
            "named tuple",
        )
            @test occursin(required_header, source)
        end

        @test occursin(r"function\s+main\s*\(", source)

        @test count("TODO(N01):", source) == 3
        for required_todo in (
            "矩形状の初期分布",
            "風上差分と陽Euler法による1step更新",
            "中心差分と陽Euler法による1step更新",
        )
            @test occursin(required_todo, source)
            todo_pattern = Regex("TODO\\(N01\\):\\s+" * required_todo)
            todo_position = findfirst(todo_pattern, source)
            opening = isnothing(todo_position) ? nothing :
                findprev("#=", source, first(todo_position))
            closing_before = isnothing(todo_position) ? nothing :
                findprev("=#", source, first(todo_position))
            closing_after = isnothing(todo_position) ? nothing :
                findnext("=#", source, last(todo_position))
            @test !isnothing(opening)
            @test !isnothing(closing_after)
            if !isnothing(opening) && !isnothing(closing_before)
                @test first(opening) > first(closing_before)
            end
        end

        for function_name in (
            "rectangular_initial_condition", "upwind_step!", "centered_step!",
            "apply_boundary!", "simulate",
        )
            attached = match(Regex(
                "\"\"\"((?:(?!\"\"\")[\\s\\S])*)\"\"\"\\s*function\\s+" *
                function_name * "\\s*\\(",
            ), source)
            @test !isnothing(attached)
            if !isnothing(attached)
                doc = only(attached.captures)
                @test occursin("# 引数", doc)
                @test occursin("# 戻り値", doc)
            end
        end
        for function_name in ("upwind_step!", "centered_step!", "apply_boundary!")
            attached = match(Regex(
                "\"\"\"((?:(?!\"\"\")[\\s\\S])*)\"\"\"\\s*function\\s+" *
                function_name * "\\s*\\(",
            ), source)
            !isnothing(attached) && @test occursin("書き換", only(attached.captures))
        end

        @test !occursin("台形部", source)
        for function_name in ("upwind_step!", "centered_step!")
            editable_prefix = match(Regex(
                "function\\s+" * function_name *
                "\\s*\\([\\s\\S]*?TODO\\(N01\\):",
            ), source)
            @test !isnothing(editable_prefix)
            if !isnothing(editable_prefix)
                @test occursin("CFL数", editable_prefix.match)
                @test occursin("copyto!", editable_prefix.match)
                @test occursin("端点", editable_prefix.match)
            end
        end

        @test occursin("include(\"provided_support.jl\")", source)
        @test isfile(N01_SUPPORT)
        support = isfile(N01_SUPPORT) ? read(N01_SUPPORT, String) : ""
        if isfile(N01_SUPPORT)
            for supplied_name in (
                "validate_initial_condition_inputs", "validate_step_inputs",
                "validate_boundary_inputs", "validate_simulation_inputs",
                "summary_section", "write_summary", "make_plots",
            )
                @test occursin("function " * supplied_name, support)
            end
            @test !occursin(r"function\s+main\s*\(", support)
            for supplied_copy in (
                "実行時の入力条件", "受講生が読解・編集する必要はありません",
                "summary.toml", "upwind.png", "centered-euler.png",
            )
                @test occursin(supplied_copy, support)
            end
        end

        combined_source = source * "\n" * support
        for name in (
            :rectangular_initial_condition, :apply_boundary!, :upwind_step!, :centered_step!,
            :simulate, :write_summary, :make_plots, :main,
        )
            @test occursin(string(name), combined_source)
        end

        if !isdefined(Main, :N01LinearAdvection)
            include(N01_RUN)
        end
        N01 = N01LinearAdvection

        x = collect(range(0.0, 2.0; length=5))
        @test N01.rectangular_initial_condition(x) == [1.0, 2.0, 2.0, 1.0, 1.0]
        @test_throws ArgumentError N01.rectangular_initial_condition([0.0, NaN, 1.0])

        boundary = fill(99.0, 5)
        @test N01.apply_boundary!(boundary; left_value=1.0) === boundary
        @test boundary[1] == 1.0
        @test boundary[end] == boundary[end - 1]

        old = [1.0, 2.0, 4.0, 8.0]
        old_copy = copy(old)
        new = similar(old)
        N01.upwind_step!(new, old, 1.0, 0.25, 0.5)
        @test new[2] == 1.5
        @test old == old_copy
        N01.centered_step!(new, old, 1.0, 0.25, 0.5)
        @test new[2] == 1.25
        @test old == old_copy

        constant = fill(3.0, 7)
        constant_new = similar(constant)
        N01.upwind_step!(constant_new, constant, 1.0, 0.1, 0.2)
        N01.apply_boundary!(constant_new; left_value=3.0)
        @test constant_new == constant
        N01.centered_step!(constant_new, constant, 1.0, 0.1, 0.2)
        N01.apply_boundary!(constant_new; left_value=3.0)
        @test constant_new == constant

        stable = N01.simulate(; scheme=:upwind)
        unstable = N01.simulate(; scheme=:centered)
        expected_keys = (:x, :u0, :u, :dx, :dt, :steps, :cfl, :minimum, :maximum)
        @test keys(stable) == expected_keys
        @test stable.x[1] == 0.0 && stable.x[end] == 2.0 && length(stable.x) == 81
        @test stable.u !== stable.u0
        @test stable.minimum >= 1.0 - 100eps()
        @test stable.maximum <= 2.0 + 100eps()
        @test unstable.minimum < 1.0 || unstable.maximum > 2.0
        @test unstable.maximum - unstable.minimum > stable.maximum - stable.minimum
        @test isapprox(stable.dt * stable.steps, 0.5; atol=100eps())
        @test isapprox(stable.cfl, stable.dt / stable.dx; atol=100eps())
        adjusted = N01.simulate(; scheme=:upwind, nx=20, c=1.0, cfl=0.6, t_final=0.37)
        @test isapprox(adjusted.dt * adjusted.steps, 0.37; atol=100eps())
        @test adjusted.cfl <= 0.6 + 100eps()
        nonunit_speed = N01.simulate(;
            scheme=:upwind, nx=31, c=2.0, cfl=0.55, t_final=0.17,
        )
        @test isapprox(
            nonunit_speed.cfl,
            2.0 * nonunit_speed.dt / nonunit_speed.dx;
            atol=100eps(),
        )

        for arguments in (
            (; scheme=:unknown), (; scheme=:upwind, nx=2), (; scheme=:upwind, c=0.0),
            (; scheme=:upwind, c=-1.0), (; scheme=:upwind, cfl=0.0),
            (; scheme=:upwind, cfl=1.1), (; scheme=:upwind, t_final=0.0),
        )
            @test_throws ArgumentError N01.simulate(; arguments...)
        end
        @test_throws ArgumentError N01.upwind_step!(old, old, 1.0, 0.1, 0.2)
        @test_throws ArgumentError N01.centered_step!(old, old, 1.0, 0.1, 0.2)

        mktempdir() do output_dir
            outputs = N01.main(; output_dir, nx=21, c=1.0, cfl=0.5, t_final=0.1)
            @test outputs.summary_path == joinpath(output_dir, "summary.toml")
            @test outputs.plot_paths.upwind == joinpath(output_dir, "upwind.png")
            @test outputs.plot_paths.centered == joinpath(output_dir, "centered-euler.png")
            paths = (outputs.summary_path, outputs.plot_paths.upwind, outputs.plot_paths.centered)
            for path in paths
                @test isfile(path)
                @test 0 < filesize(path) <= 5 * 1024^2
            end
            png_signature = UInt8[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]
            for path in (outputs.plot_paths.upwind, outputs.plot_paths.centered)
                @test open(io -> read(io, 8), path) == png_signature
            end
            @test sum(filesize, readdir(output_dir; join=true)) <= 10 * 1024^2

            summary = TOML.parsefile(outputs.summary_path)
            @test Set(keys(summary)) == Set(["course_id", "grid", "upwind", "centered_euler"])
            @test summary["course_id"] == "N01"
            @test summary["grid"]["nx"] == length(outputs.upwind.x) == 21
            @test summary["grid"]["dx"] == outputs.upwind.dx
            for (section, scheme, result) in (
                ("upwind", "upwind-euler", outputs.upwind),
                ("centered_euler", "centered-euler", outputs.centered),
            )
                parsed = summary[section]
                @test parsed["scheme"] == scheme
                @test parsed["cfl"] == result.cfl
                @test parsed["dt"] == result.dt
                @test parsed["steps"] == result.steps
                @test parsed["minimum"] == result.minimum
                @test parsed["maximum"] == result.maximum
                initial_minimum, initial_maximum = extrema(result.u0)
                overshoot = max(result.maximum - initial_maximum, 0.0)
                undershoot = max(initial_minimum - result.minimum, 0.0)
                tolerance = 100eps(Float64) * max(
                    abs(initial_minimum), abs(initial_maximum), 1.0,
                )
                @test parsed["overshoot"] == overshoot
                @test parsed["undershoot"] == undershoot
                @test parsed["overshoot_occurred"] == (overshoot > tolerance)
                @test parsed["undershoot_occurred"] == (undershoot > tolerance)
            end
        end
    end

    @test isfile(N01_STUDENT_TEST)
    if isfile(N01_STUDENT_TEST)
        student_test = read(N01_STUDENT_TEST, String)
        state = n01_student_test_state(student_test)
        @test !occursin("isdefined(N01LinearAdvection, :simulate)", student_test)
        @test !occursin("[1.0, 1.5, 3.0, 8.0]", student_test)
        @test state.is_scaffold || state.is_completed
    end
    @test isfile(N01_LOG)
    if isfile(N01_LOG)
        learning_log = read(N01_LOG, String)
        @test occursin("入力", learning_log)
        @test occursin("期待値", learning_log)
        @test occursin("保証すること", learning_log)
        @test occursin("保証しないこと", learning_log)
    end
end
