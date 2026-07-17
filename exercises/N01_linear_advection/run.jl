module N01LinearAdvection

using Plots
using TOML

export rectangular_initial_condition, apply_boundary!, upwind_step!, centered_step!
export simulate, write_summary, make_plots, main

const DEFAULT_OUTPUT_DIR = normpath(joinpath(@__DIR__, "..", "..", "results", "N01"))

# === 学生が実装する3つの関数 ===

"""N01の移流実験で使う矩形状の初期分布を返す。"""
function rectangular_initial_condition(
    x::AbstractVector{<:Real};
    base::Real = 1.0,
    plateau::Real = 2.0,
    plateau_start::Real = 0.5,
    plateau_end::Real = 1.0,
)
    isempty(x) && throw(ArgumentError("xを空にすることはできません"))
    all(isfinite, x) || throw(ArgumentError("xの全要素を有限値にしてください"))
    all(isfinite, (base, plateau, plateau_start, plateau_end)) ||
        throw(ArgumentError("初期条件のパラメータを有限値にしてください"))
    all(diff(x) .> 0) || throw(ArgumentError("xを狭義単調増加にしてください"))
    first(x) <= plateau_start <= plateau_end <= last(x) ||
        throw(ArgumentError("矩形領域を計算領域内に置いてください"))

    # TODO(N01): 矩形状の初期分布を実装する。
    return fill(float(base), length(x))
end

"""風上差分と陽Euler法で1ステップ進める。"""
function upwind_step!(u_new, u_old, c::Real, dt::Real, dx::Real)
    validate_step_inputs(u_new, u_old, c, dt, dx)
    # courantは1ステップで進む格子幅の割合を表すCFL数です。
    courant = c * dt / dx
    # copyto!で古い値を複製し、内部を更新する間も両端点の値を保ちます。
    copyto!(u_new, u_old)
    for i in 2:(length(u_old) - 1)
        # TODO(N01): 風上差分と陽Eulerによる更新式を実装する。
        u_new[i] = u_old[i]
    end
    return u_new
end

"""意図的に不安定な中心差分と陽Euler法で1ステップ進める。"""
function centered_step!(u_new, u_old, c::Real, dt::Real, dx::Real)
    validate_step_inputs(u_new, u_old, c, dt, dx)
    # courantは1ステップで進む格子幅の割合を表すCFL数です。
    courant = c * dt / dx
    # copyto!で古い値を複製し、内部を更新する間も両端点の値を保ちます。
    copyto!(u_new, u_old)
    for i in 2:(length(u_old) - 1)
        # TODO(N01): 中心差分と陽Eulerによる更新式を実装する。
        u_new[i] = u_old[i]
    end
    return u_new
end

# === 境界条件と時間発展の流れ ===

"""左端を固定値、右端をゼロ勾配条件にする。"""
function apply_boundary!(u::AbstractVector{<:Real}; left_value::Real = 1.0)
    length(u) >= 2 || throw(ArgumentError("uには2点以上が必要です"))
    isfinite(left_value) || throw(ArgumentError("left_valueを有限値にしてください"))
    u[1] = left_value
    u[end] = u[end - 1]
    return u
end

"""指定したN01の差分法を実行し、初期値・最終値・診断量を返す。"""
function simulate(;
    scheme,
    nx::Integer = 81,
    c::Real = 1.0,
    cfl::Real = 0.5,
    t_final::Real = 0.5,
)
    scheme in (:upwind, :centered) ||
        throw(ArgumentError("schemeには:upwindまたは:centeredを指定してください"))
    nx isa Bool && throw(ArgumentError("nxには格子点数を表す整数を指定してください"))
    nx >= 3 || throw(ArgumentError("nxは3以上にしてください"))
    all(isfinite, (c, cfl, t_final)) ||
        throw(ArgumentError("c、cfl、t_finalを有限値にしてください"))
    c > 0 || throw(ArgumentError("N01では正の移流速度だけを扱います"))
    0 < cfl <= 1 || throw(ArgumentError("cflは0 < cfl <= 1を満たす必要があります"))
    t_final > 0 || throw(ArgumentError("t_finalは正にしてください"))

    x = collect(range(0.0, 2.0; length = nx))
    dx = x[2] - x[1]
    nominal_dt = cfl * dx / c
    steps = ceil(Int, t_final / nominal_dt)
    dt = t_final / steps
    actual_cfl = c * dt / dx

    u0 = rectangular_initial_condition(x)
    u_old = copy(u0)
    u_new = similar(u_old)
    step! = scheme === :upwind ? upwind_step! : centered_step!

    # 各ステップで新しい値を計算し、境界条件を適用してから二つのバッファを交換する。
    for _ in 1:steps
        step!(u_new, u_old, c, dt, dx)
        apply_boundary!(u_new)
        u_old, u_new = u_new, u_old
    end

    return (
        x = x,
        u0 = u0,
        u = u_old,
        dx = dx,
        dt = dt,
        steps = steps,
        cfl = actual_cfl,
        minimum = minimum(u_old),
        maximum = maximum(u_old),
    )
end

# === 提供済みの検証・出力処理 ===
# ここから下の詳細な入力検証、TOML出力、作図、実行処理は提供済みです。

"""1ステップ分の入力が計算条件を満たすか確認する。"""
function validate_step_inputs(u_new, u_old, c, dt, dx)
    u_new === u_old && throw(ArgumentError("新旧で別々のバッファを使ってください"))
    length(u_new) == length(u_old) >= 3 ||
        throw(ArgumentError("二つのバッファを同じ長さの3点以上にしてください"))
    all(isfinite, u_old) || throw(ArgumentError("u_oldの全要素を有限値にしてください"))
    all(isfinite, (c, dt, dx)) || throw(ArgumentError("c、dt、dxを有限値にしてください"))
    c > 0 || throw(ArgumentError("N01では正の移流速度だけを扱います"))
    dt > 0 || throw(ArgumentError("dtは正にしてください"))
    dx > 0 || throw(ArgumentError("dxは正にしてください"))
    return nothing
end

"""一つの差分法についてTOMLへ書き出す診断量を作る。"""
function summary_section(scheme::String, result)
    initial_minimum, initial_maximum = extrema(result.u0)
    overshoot = max(result.maximum - initial_maximum, 0.0)
    undershoot = max(initial_minimum - result.minimum, 0.0)
    tolerance = 100eps(Float64) * max(
        abs(initial_minimum), abs(initial_maximum), 1.0,
    )
    return Dict(
        "scheme" => scheme,
        "cfl" => result.cfl,
        "dt" => result.dt,
        "steps" => result.steps,
        "minimum" => result.minimum,
        "maximum" => result.maximum,
        "overshoot" => overshoot,
        "undershoot" => undershoot,
        "overshoot_occurred" => overshoot > tolerance,
        "undershoot_occurred" => undershoot > tolerance,
    )
end

"""機械可読な診断量を書き出し、summary.tomlのパスを返す。"""
function write_summary(output_dir::AbstractString, upwind, centered)
    mkpath(output_dir)
    path = joinpath(output_dir, "summary.toml")
    summary = Dict(
        "course_id" => "N01",
        "grid" => Dict("nx" => length(upwind.x), "dx" => upwind.dx),
        "upwind" => summary_section("upwind-euler", upwind),
        "centered_euler" => summary_section("centered-euler", centered),
    )
    open(path, "w") do io
        TOML.print(io, summary; sorted = true)
    end
    return path
end

"""公式の比較図を二つ作り、それぞれのパスを返す。"""
function make_plots(output_dir::AbstractString, upwind, centered)
    mkpath(output_dir)
    upwind_path = joinpath(output_dir, "upwind.png")
    centered_path = joinpath(output_dir, "centered-euler.png")

    for (result, title, path) in (
        (upwind, "Upwind + Euler (stable)", upwind_path),
        (centered, "Centered + Euler (intentionally unstable)", centered_path),
    )
        plot(
            result.x,
            result.u0;
            label = "initial",
            linewidth = 2,
            xlabel = "x",
            ylabel = "u",
            title = title,
        )
        plot!(result.x, result.u; label = "final", linewidth = 2)
        savefig(path)
    end
    return (upwind = upwind_path, centered = centered_path)
end

"""N01の二つの比較計算を実行し、公式出力をすべて書き出す。"""
function main(;
    output_dir::AbstractString = DEFAULT_OUTPUT_DIR,
    nx::Integer = 81,
    c::Real = 1.0,
    cfl::Real = 0.5,
    t_final::Real = 0.5,
)
    upwind = simulate(; scheme = :upwind, nx, c, cfl, t_final)
    centered = simulate(; scheme = :centered, nx, c, cfl, t_final)
    summary_path = write_summary(output_dir, upwind, centered)
    plot_paths = make_plots(output_dir, upwind, centered)
    println("N01の出力を書き込みました: $(abspath(output_dir))")
    return (; upwind, centered, summary_path, plot_paths)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

end
