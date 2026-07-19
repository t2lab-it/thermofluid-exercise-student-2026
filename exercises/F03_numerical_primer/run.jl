module F03NumericalPrimer

export backward_difference_at, centered_difference_at, uniform_grid

function uniform_grid(xmin::Real, xmax::Real, n::Integer)
    n isa Bool && throw(ArgumentError("n must be an integer of at least 2, not Bool"))
    n >= 2 || throw(ArgumentError("n must be at least 2"))
    isfinite(xmin) && isfinite(xmax) || throw(ArgumentError("grid endpoints must be finite"))
    xmax > xmin || throw(ArgumentError("xmax must be greater than xmin"))

    # TODO(F03): return n equally spaced coordinates including both endpoints.
    fill(float(xmin), Int(n))
end

function validate_field(u::AbstractVector{<:Real})
    isempty(u) && throw(ArgumentError("u must not be empty"))
    all(isfinite, u) || throw(ArgumentError("u must contain only finite values"))
    nothing
end

function validate_spacing(dx::Real)
    isfinite(dx) && dx > 0 || throw(ArgumentError("dx must be finite and positive"))
    nothing
end

function backward_difference_at(u::AbstractVector{<:Real}, i::Integer, dx::Real)
    validate_field(u)
    validate_spacing(dx)
    i isa Bool && throw(ArgumentError("i must be an integer index, not Bool"))
    2 <= i <= length(u) || throw(ArgumentError("backward difference requires 2 <= i <= length(u)"))

    # TODO(F03): implement (u[i] - u[i - 1]) / dx.
    zero(float((u[i] - u[i - 1]) / dx))
end

function centered_difference_at(u::AbstractVector{<:Real}, i::Integer, dx::Real)
    validate_field(u)
    validate_spacing(dx)
    i isa Bool && throw(ArgumentError("i must be an integer index, not Bool"))
    2 <= i <= length(u) - 1 || throw(ArgumentError(
        "centered difference requires 2 <= i <= length(u) - 1",
    ))

    # TODO(F03): implement (u[i + 1] - u[i - 1]) / (2 * dx).
    zero(float((u[i + 1] - u[i - 1]) / (2 * dx)))
end

end


if abspath(PROGRAM_FILE) == @__FILE__
    x = F03NumericalPrimer.uniform_grid(0.0, 1.0, 5)
    u = 3 .* x .+ 2
    dx = 0.25
    println("grid = ", x)
    println("backward derivative = ", F03NumericalPrimer.backward_difference_at(u, 3, dx))
    println("centered derivative = ", F03NumericalPrimer.centered_difference_at(u, 3, dx))
end
