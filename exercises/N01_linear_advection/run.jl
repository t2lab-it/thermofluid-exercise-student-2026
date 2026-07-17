module N01LinearAdvection

using Plots
using TOML

export rectangular_initial_condition, apply_boundary!, upwind_step!, centered_step!
export simulate, write_summary, make_plots, main

const DEFAULT_OUTPUT_DIR = normpath(joinpath(@__DIR__, "..", "..", "results", "N01"))

"""Return the rectangular pulse used by the N01 advection experiment."""
function rectangular_initial_condition(
    x::AbstractVector{<:Real};
    base::Real = 1.0,
    plateau::Real = 2.0,
    plateau_start::Real = 0.5,
    plateau_end::Real = 1.0,
)
    isempty(x) && throw(ArgumentError("x must not be empty"))
    all(isfinite, x) || throw(ArgumentError("x must contain only finite values"))
    all(isfinite, (base, plateau, plateau_start, plateau_end)) ||
        throw(ArgumentError("initial-condition parameters must be finite"))
    all(diff(x) .> 0) || throw(ArgumentError("x must be strictly increasing"))
    first(x) <= plateau_start <= plateau_end <= last(x) ||
        throw(ArgumentError("the plateau must lie inside the domain"))

    # TODO(N01): choose `plateau` only where plateau_start <= x[i] <= plateau_end.
    return fill(float(base), length(x))
end

"""Apply the fixed left value and a zero-gradient condition at the right edge."""
function apply_boundary!(u::AbstractVector{<:Real}; left_value::Real = 1.0)
    length(u) >= 2 || throw(ArgumentError("u must contain at least two points"))
    isfinite(left_value) || throw(ArgumentError("left_value must be finite"))
    u[1] = left_value
    u[end] = u[end - 1]
    return u
end

function validate_step_inputs(u_new, u_old, c, dt, dx)
    u_new === u_old && throw(ArgumentError("use separate old and new buffers"))
    length(u_new) == length(u_old) >= 3 ||
        throw(ArgumentError("both buffers must have the same length of at least three"))
    all(isfinite, u_old) || throw(ArgumentError("u_old must contain only finite values"))
    all(isfinite, (c, dt, dx)) || throw(ArgumentError("c, dt, and dx must be finite"))
    c > 0 || throw(ArgumentError("N01 supports only positive advection speed"))
    dt > 0 || throw(ArgumentError("dt must be positive"))
    dx > 0 || throw(ArgumentError("dx must be positive"))
    return nothing
end

"""Advance one step with first-order upwind space and forward Euler time."""
function upwind_step!(u_new, u_old, c::Real, dt::Real, dx::Real)
    validate_step_inputs(u_new, u_old, c, dt, dx)
    courant = c * dt / dx
    copyto!(u_new, u_old)
    for i in 2:(length(u_old) - 1)
        # TODO(N01): subtract courant times the backward difference in u.
        u_new[i] = u_old[i]
    end
    return u_new
end

"""Advance one intentionally unstable step with centered space and Euler time."""
function centered_step!(u_new, u_old, c::Real, dt::Real, dx::Real)
    validate_step_inputs(u_new, u_old, c, dt, dx)
    courant = c * dt / dx
    copyto!(u_new, u_old)
    for i in 2:(length(u_old) - 1)
        # TODO(N01): subtract courant times the centered difference in u.
        u_new[i] = u_old[i]
    end
    return u_new
end

"""Run one N01 scheme and return the initial and final fields plus diagnostics."""
function simulate(;
    scheme,
    nx::Integer = 81,
    c::Real = 1.0,
    cfl::Real = 0.5,
    t_final::Real = 0.5,
)
    scheme in (:upwind, :centered) ||
        throw(ArgumentError("scheme must be :upwind or :centered"))
    nx isa Bool && throw(ArgumentError("nx must be an integer point count"))
    nx >= 3 || throw(ArgumentError("nx must be at least 3"))
    all(isfinite, (c, cfl, t_final)) ||
        throw(ArgumentError("c, cfl, and t_final must be finite"))
    c > 0 || throw(ArgumentError("N01 supports only positive advection speed"))
    0 < cfl <= 1 || throw(ArgumentError("cfl must satisfy 0 < cfl <= 1"))
    t_final > 0 || throw(ArgumentError("t_final must be positive"))

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

"""Write machine-readable diagnostics and return the summary path."""
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

"""Create the two official comparison plots and return their paths."""
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

"""Run both N01 comparisons and write all official outputs."""
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
    println("N01 outputs written to $(abspath(output_dir))")
    return (; upwind, centered, summary_path, plot_paths)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

end
