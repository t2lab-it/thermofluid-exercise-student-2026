using Test
using TOML

const N01_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const N01_RUN = joinpath(N01_ROOT, "exercises", "N01_linear_advection", "run.jl")
const N01_TASK = joinpath(N01_ROOT, "exercises", "N01_linear_advection", "TASK.md")
const N01_LOG = joinpath(N01_ROOT, "learning_logs", "templates", "N01.md")
const N01_STUDENT_TEST = joinpath(N01_ROOT, "test", "student", "N01.jl")
const N01_NUMERICAL_FUNCTIONS = Set((
    :rectangular_initial_condition,
    :upwind_step!,
    :centered_step!,
    :simulate,
))

function n01_ast_contains(predicate, node)
    predicate(node) && return true
    node isa Expr || return false
    node.head in (:quote, :inert, :function, :macro, :->) && return false
    return any(child -> n01_ast_contains(predicate, child), node.args)
end

function n01_numerical_call_name(node)
    node isa Expr && node.head == :call || return nothing
    callee = first(node.args)
    callee isa Expr && callee.head == :. && length(callee.args) == 2 || return nothing
    module_name, quoted_name = callee.args
    module_name == :N01LinearAdvection || return nothing
    quoted_name isa QuoteNode || return nothing
    return quoted_name.value in N01_NUMERICAL_FUNCTIONS ? quoted_name.value : nothing
end

n01_numerical_call(node) = !isnothing(n01_numerical_call_name(node))

function n01_mutating_call(node)
    node isa Expr && node.head == :call || return false
    callee = first(node.args)
    name = if callee isa Symbol
        callee
    elseif callee isa Expr && callee.head == :. && length(callee.args) == 2 &&
            callee.args[2] isa QuoteNode
        callee.args[2].value
    else
        nothing
    end
    return !isnothing(name) && endswith(String(name), "!")
end

function n01_assignment_like_mutation(node)
    node isa Expr && node.head isa Symbol || return false
    return node.head != :(=) && endswith(String(node.head), "=")
end

n01_has_uncertain_mutation(node) = n01_ast_contains(
    candidate ->
        (n01_mutating_call(candidate) &&
            isnothing(n01_numerical_call_name(candidate))) ||
        n01_assignment_like_mutation(candidate),
    node,
)

function n01_test_assertion(node)
    node isa Expr && node.head == :macrocall && length(node.args) >= 3 || return nothing
    first(node.args) == Symbol("@test") || return nothing
    return node.args[3]
end

function n01_in_place_destination(node)
    n01_numerical_call_name(node) in (:upwind_step!, :centered_step!) || return nothing
    for argument in Iterators.drop(node.args, 1)
        argument isa LineNumberNode && continue
        argument isa Expr && argument.head == :parameters && continue
        return argument isa Symbol ? argument : nothing
    end
    return nothing
end

function n01_mark_in_place_results!(numerical, expected, node)
    node isa Expr || return nothing
    node.head in (:quote, :inert, :function, :macro, :->) && return nothing

    if node.head == :if && first(node.args) === false
        length(node.args) >= 3 &&
            n01_mark_in_place_results!(numerical, expected, node.args[3])
        return nothing
    end

    if node.head == :if && first(node.args) === true
        length(node.args) >= 2 &&
            n01_mark_in_place_results!(numerical, expected, node.args[2])
        return nothing
    end

    destination = n01_in_place_destination(node)
    if !isnothing(destination)
        delete!(expected, destination)
        push!(numerical, destination)
    end
    foreach(child -> n01_mark_in_place_results!(numerical, expected, child), node.args)
    return nothing
end

function n01_comparison_operands(assertion)
    assertion isa Expr && assertion.head == :call || return nothing
    comparator = first(assertion.args)
    comparator in (:(==), :≈, :isapprox) || return nothing
    operands = filter(
        argument -> !(argument isa LineNumberNode) &&
            !(argument isa Expr && argument.head == :parameters),
        assertion.args[2:end],
    )
    length(operands) == 2 || return nothing
    return operands[1], operands[2]
end

function n01_uses_numerical_result(node, numerical)
    n01_ast_contains(n01_numerical_call, node) && return true
    return n01_ast_contains(
        candidate -> candidate isa Symbol && candidate in numerical,
        node,
    )
end

function n01_numerical_term(node, numerical)
    node isa Symbol && node in numerical && return node
    n01_numerical_call(node) && return node
    node isa Expr && node.head in (:., :ref) &&
        n01_uses_numerical_result(node, numerical) && return node
    return nothing
end

function n01_has_multiple_numerical_terms(node, numerical)
    terms = Any[]
    function collect_terms(candidate)
        term = n01_numerical_term(candidate, numerical)
        if !isnothing(term)
            push!(terms, term)
            return nothing
        end
        candidate isa Expr || return nothing
        candidate.head in (:quote, :inert, :function, :macro, :->) && return nothing
        foreach(collect_terms, candidate.args)
        return nothing
    end
    collect_terms(node)
    return length(terms) > 1
end

function n01_uses_independent_expected(node, numerical, expected)
    n01_uses_numerical_result(node, numerical) && return false
    return n01_ast_contains(
        candidate ->
            (candidate isa Number && !(candidate isa Bool)) ||
            (candidate isa Symbol && candidate in expected),
        node,
    )
end

function n01_assertion_compares_numerical_result(assertion, numerical, expected)
    operands = n01_comparison_operands(assertion)
    isnothing(operands) && return false
    left, right = operands
    isequal(left, right) && return false
    n01_has_uncertain_mutation(assertion) && return false
    (n01_has_multiple_numerical_terms(left, numerical) ||
        n01_has_multiple_numerical_terms(right, numerical)) && return false

    left_numerical = n01_uses_numerical_result(left, numerical)
    right_numerical = n01_uses_numerical_result(right, numerical)
    left_expected = n01_uses_independent_expected(left, numerical, expected)
    right_expected = n01_uses_independent_expected(right, numerical, expected)
    return (
        (left_numerical && !right_numerical && right_expected) ||
        (right_numerical && !left_numerical && left_expected))
end

function n01_analyze_test_statements!(numerical, expected, has_meaningful_test, node)
    node isa Expr || return nothing
    node.head in (:quote, :inert, :function, :macro, :->) && return nothing

    if node.head in (:toplevel, :block)
        for child in node.args
            n01_analyze_test_statements!(numerical, expected, has_meaningful_test, child)
        end
        return nothing
    end

    assertion = n01_test_assertion(node)
    if !isnothing(assertion)
        has_meaningful_test[] |=
            n01_assertion_compares_numerical_result(assertion, numerical, expected)
        if n01_has_uncertain_mutation(assertion)
            empty!(numerical)
            empty!(expected)
        else
            n01_mark_in_place_results!(numerical, expected, assertion)
        end
        return nothing
    end

    if node.head == :macrocall
        if first(node.args) == Symbol("@testset")
            for child in node.args
                child isa Expr && child.head in (:toplevel, :block) || continue
                n01_analyze_test_statements!(numerical, expected, has_meaningful_test, child)
            end
        end
        return nothing
    end

    if node.head == :(=) && length(node.args) == 2
        variable, value = node.args
        value_is_numerical =
            !isnothing(n01_numerical_term(value, numerical))
        value_is_expected =
            !value_is_numerical &&
            n01_uses_independent_expected(value, numerical, expected)
        if variable isa Symbol
            delete!(numerical, variable)
            delete!(expected, variable)
            value_is_numerical && push!(numerical, variable)
            value_is_expected && push!(expected, variable)
        else
            empty!(numerical)
            empty!(expected)
        end
        if n01_has_uncertain_mutation(value)
            empty!(numerical)
            empty!(expected)
        else
            n01_mark_in_place_results!(numerical, expected, value)
        end
        return nothing
    end

    if n01_has_uncertain_mutation(node)
        empty!(numerical)
        empty!(expected)
    else
        n01_mark_in_place_results!(numerical, expected, node)
    end
    return nothing
end

function n01_student_test_state(source)
    parsed = try
        Meta.parseall(source)
    catch
        return (; is_scaffold = false, is_completed = false)
    end

    scaffold_marker = "STUDENT_TEST_REQUIRED(N01)"
    has_literal_false = n01_ast_contains(node -> n01_test_assertion(node) === false, parsed)
    numerical = Set{Symbol}()
    expected = Set{Symbol}()
    has_meaningful_test = Ref(false)
    n01_analyze_test_statements!(numerical, expected, has_meaningful_test, parsed)

    is_scaffold = occursin(scaffold_marker, source) && has_literal_false
    is_completed =
        !occursin(scaffold_marker, source) &&
        !has_literal_false &&
        has_meaningful_test[]
    return (; is_scaffold, is_completed)
end

@testset "N01 self-contained linear advection" begin
    @testset "student numerical-test detector" begin
        scaffold = n01_student_test_state("""
            # STUDENT_TEST_REQUIRED(N01): student-owned placeholder
            @test false
        """)
        @test scaffold.is_scaffold
        @test !scaffold.is_completed

        for rejected_source in (
            """
            # N01LinearAdvection.simulate(; scheme=:upwind)
            @test true
            """,
            """
            "N01LinearAdvection.simulate(; scheme=:upwind)"
            @test 1 == 1
            """,
            """
            quote
                N01LinearAdvection.simulate(; scheme=:upwind)
            end
            @test 1 == 1
            """,
            """
            @test isdefined(N01LinearAdvection, :simulate)
            """,
            """
            N01LinearAdvection.simulate(; scheme=:upwind)
            @test 1 == 1
            """,
            """
            function never_called()
                N01LinearAdvection.simulate(; scheme=:upwind)
            end
            @test 1 == 1
            """,
            """
            result = N01LinearAdvection.simulate(; scheme=:upwind)
            result = 1
            @test result == 1
            """,
            """
            u_old = [1.0, 2.0, 4.0, 8.0]
            buffers = [similar(u_old)]
            N01LinearAdvection.upwind_step!(
                buffers[1], u_old, 1.0, 0.25, 0.5,
            )
            buffers[1] = fill(9.0, 4)
            @test buffers[1][2] == 9.0
            """,
            """
            u_old = [1.0, 2.0, 4.0, 8.0]
            buffers = [similar(u_old)]
            N01LinearAdvection.upwind_step!(
                buffers[1], u_old, 1.0, 0.25, 0.5,
            )
            buffers = [fill(9.0, 4)]
            @test buffers[1][2] == 9.0
            """,
            """
            u_old = [1.0, 2.0, 4.0, 8.0]
            u_new = similar(u_old)
            if false
                N01LinearAdvection.upwind_step!(
                    u_new, u_old, 1.0, 0.25, 0.5,
                )
            end
            @test u_new[2] == 2.0
            """,
            """
            result = N01LinearAdvection.simulate(; scheme=:upwind)
            @test result.minimum == result.minimum
            """,
            """
            @test N01LinearAdvection.simulate(; scheme=:upwind).minimum ==
                N01LinearAdvection.simulate(; scheme=:upwind).minimum
            """,
            """
            result = N01LinearAdvection.simulate(; scheme=:upwind)
            expected = result.minimum
            @test result.minimum == expected
            """,
            """
            result = N01LinearAdvection.simulate(; scheme=:upwind)
            @test result.minimum == identity(result.minimum)
            """,
            """
            result = N01LinearAdvection.simulate(; scheme=:upwind)
            @test result.minimum - result.minimum == 0.0
            """,
            """
            result = N01LinearAdvection.simulate(; scheme=:upwind)
            numerical_alias = result.minimum
            @test numerical_alias - numerical_alias == 0.0
            """,
            """
            result = N01LinearAdvection.simulate(; scheme=:upwind)
            cancelled = result.minimum - result.minimum
            @test cancelled == 0.0
            """,
            """
            result = N01LinearAdvection.simulate(; scheme=:upwind)
            numerical_alias = result.minimum
            cancelled = numerical_alias - numerical_alias
            @test cancelled == 0.0
            """,
            """
            result = N01LinearAdvection.simulate(; scheme=:upwind)
            minimum_alias = result.minimum
            same_minimum = minimum_alias
            @test minimum_alias - same_minimum == 0.0
            """,
            """
            result = N01LinearAdvection.simulate(; scheme=:upwind)
            result_alias = result
            @test result.minimum == result_alias.minimum
            """,
            """
            u_old = [1.0, 2.0, 4.0, 8.0]
            u_new = similar(u_old)
            N01LinearAdvection.upwind_step!(u_new, u_old, 1.0, 0.25, 0.5)
            fill!(u_new, 9.0)
            @test u_new[2] == 9.0
            """,
            """
            u_old = [1.0, 2.0, 4.0, 8.0]
            u_new = similar(u_old)
            N01LinearAdvection.upwind_step!(u_new, u_old, 1.0, 0.25, 0.5)
            @test fill!(u_new, 9.0) == fill(9.0, 4)
            @test u_new[2] == 9.0
            """,
            """
            result = N01LinearAdvection.simulate(; scheme=:upwind)
            result_alias = result.u
            fill!(result_alias, 9.0)
            @test result_alias[1] == 9.0
            """,
            """
            result = N01LinearAdvection.simulate(; scheme=:upwind)
            expected = [1.0]
            expected[1] = result.minimum
            @test result.minimum == expected[1]
            """,
            """
            result = N01LinearAdvection.simulate(; scheme=:upwind)
            expected = [1.0]
            expected_alias = expected
            expected_alias[1] = result.minimum
            @test result.minimum == expected[1]
            """,
            """
            result = N01LinearAdvection.simulate(; scheme=:upwind)
            expected = [1.0]
            expected .= result.minimum
            @test result.minimum == expected[1]
            """,
            """
            result = N01LinearAdvection.simulate(; scheme=:upwind)
            expected = [0.0]
            expected[1] += result.minimum
            @test result.minimum == expected[1]
            """,
            """
            u_old = [1.0, 2.0, 4.0, 8.0]
            u_new = similar(u_old)
            if true
                nothing
            else
                N01LinearAdvection.upwind_step!(
                    u_new, u_old, 1.0, 0.25, 0.5,
                )
            end
            @test u_new[2] == 2.0
            """,
            """
            result = N01LinearAdvection.simulate(; scheme=:upwind)
            @test result.minimum >= -Inf
            """,
            """
            result = N01LinearAdvection.simulate(; scheme=:upwind)
            @test result.minimum <= 1.0e99
            """,
            "result = N01LinearAdvection.simulate(",
        )
            rejected = n01_student_test_state(rejected_source)
            @test !rejected.is_scaffold
            @test !rejected.is_completed
        end

        direct_assertion = n01_student_test_state("""
            @test N01LinearAdvection.simulate(; scheme=:upwind).minimum == 1.0
        """)
        @test !direct_assertion.is_scaffold
        @test direct_assertion.is_completed

        assigned_result = n01_student_test_state("""
            result = N01LinearAdvection.simulate(; scheme=:upwind)
            @test result.minimum == 1.0
        """)
        @test !assigned_result.is_scaffold
        @test assigned_result.is_completed

        assigned_expected = n01_student_test_state("""
            result = N01LinearAdvection.simulate(; scheme=:upwind)
            expected = 1.0
            @test result.minimum == expected
        """)
        @test !assigned_expected.is_scaffold
        @test assigned_expected.is_completed

        rectangular_vector = n01_student_test_state("""
            x = collect(range(0.0, 2.0; length=5))
            @test N01LinearAdvection.rectangular_initial_condition(x) ==
                [1.0, 2.0, 2.0, 1.0, 1.0]
        """)
        @test !rectangular_vector.is_scaffold
        @test rectangular_vector.is_completed

        hand_computed_expected = n01_student_test_state("""
            u_old = [1.0, 2.0, 4.0, 8.0]
            u_new = similar(u_old)
            expected = u_old[2] - 0.5 * (u_old[2] - u_old[1])
            N01LinearAdvection.upwind_step!(u_new, u_old, 1.0, 0.25, 0.5)
            @test u_new[2] == expected
        """)
        @test !hand_computed_expected.is_scaffold
        @test hand_computed_expected.is_completed

        upwind_in_place = n01_student_test_state("""
            u_old = [1.0, 2.0, 4.0, 8.0]
            u_new = similar(u_old)
            N01LinearAdvection.upwind_step!(u_new, u_old, 1.0, 0.25, 0.5)
            @test u_new[2] == 1.5
        """)
        @test !upwind_in_place.is_scaffold
        @test upwind_in_place.is_completed

        centered_in_place = n01_student_test_state("""
            u_old = [1.0, 2.0, 4.0, 8.0]
            u_new = similar(u_old)
            N01LinearAdvection.centered_step!(u_new, u_old, 1.0, 0.25, 0.5)
            @test u_new[2] == 1.25
        """)
        @test !centered_in_place.is_scaffold
        @test centered_in_place.is_completed
    end

    project = TOML.parsefile(joinpath(N01_ROOT, "Project.toml"))
    @test Set(keys(project["deps"])) == Set(["Plots", "TOML"])
    @test !occursin("CairoMakie", read(joinpath(N01_ROOT, "Manifest.toml"), String))

    @test isfile(N01_RUN)
    if isfile(N01_RUN)
        source = read(N01_RUN, String)
        @test !occursin("ThermofluidExercise", source)
        @test !occursin("Vector{Vector", source)
        section_markers = (
            "# === 学生が実装する3つの関数 ===",
            "# === 境界条件と時間発展の流れ ===",
            "# === 提供済みの検証・出力処理 ===",
        )
        @test count("# ===", source) == length(section_markers)
        marker_positions = map(marker -> findfirst(marker, source), section_markers)
        @test all(!isnothing, marker_positions)
        if all(!isnothing, marker_positions)
            @test issorted(map(first, marker_positions))
        end
        @test count("TODO(N01)", source) == 3
        for marker in (
            "# TODO(N01): 矩形状の初期分布を実装する。",
            "# TODO(N01): 風上差分と陽Eulerによる更新式を実装する。",
            "# TODO(N01): 中心差分と陽Eulerによる更新式を実装する。",
        )
            @test count(marker, source) == 1
        end
        for function_name in (
            "rectangular_initial_condition", "upwind_step!", "centered_step!",
        )
            attached = match(Regex(
                "\"\"\"((?:(?!\"\"\")[\\s\\S])*)\"\"\"\\s*function\\s+" *
                function_name * "\\s*\\(",
            ), source)
            @test !isnothing(attached)
            if !isnothing(attached)
                @test occursin(r"[ぁ-んァ-ヶ一-龠]", only(attached.captures))
            end
        end
        @test !occursin("台形部", source)
        for function_name in ("upwind_step!", "centered_step!")
            editable_prefix = match(Regex(
                "function\\s+" * function_name *
                "\\s*\\([\\s\\S]*?# TODO\\(N01\\):",
            ), source)
            @test !isnothing(editable_prefix)
            if !isnothing(editable_prefix)
                @test occursin("CFL数", editable_prefix.match)
                @test occursin("copyto!", editable_prefix.match)
                @test occursin("端点", editable_prefix.match)
            end
        end
        for name in (
            :rectangular_initial_condition, :apply_boundary!, :upwind_step!, :centered_step!,
            :simulate, :write_summary, :make_plots, :main,
        )
            @test occursin(string(name), source)
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

    @test isfile(N01_TASK)
    if isfile(N01_TASK)
        task = read(N01_TASK, String)
        @test occursin("https://t2lab-it.github.io/thermofluid-exercise-2026/assignments/N01.html", task)
        @test occursin("julia --project=. scripts/course.jl start N01", task)
        @test occursin("self-contained", lowercase(task))
        @test occursin("風上差分", task) && occursin("安定", task)
        @test occursin("中心差分", task) && occursin("意図的", task) && occursin("不安定", task)
        @test occursin("results/N01/upwind.png", task)
        @test occursin("results/N01/centered-euler.png", task)
        @test occursin("results/N01/summary.toml", task)
        @test occursin("デバッグ補助", task)
        @test occursin("秘密", task)
        @test occursin("出力処理は提供済み", task)
        @test occursin("時間ループ", task) && occursin("バッファ交換", task)
        @test occursin("詳細な入力検証", task) && occursin("提供済み", task)
        @test !occursin("CairoMakie", task)
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
