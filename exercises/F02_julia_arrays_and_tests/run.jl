module F02JuliaArraysAndTests

export mean_temperature, temperature_anomaly

function validate_temperatures(values::AbstractVector{<:Real})
    isempty(values) && throw(ArgumentError("temperature values must not be empty"))
    all(isfinite, values) || throw(
        ArgumentError("temperature values must all be finite; remove NaN and Inf values"),
    )
    nothing
end

function mean_temperature(values::AbstractVector{<:Real})
    validate_temperatures(values)
    # TODO(F02): compute the sum of every value and divide by the length.
    zero(float(first(values)))
end

function temperature_anomaly(values::AbstractVector{<:Real})
    validate_temperatures(values)
    # TODO(F02): return a new array containing value - mean_temperature(values).
    collect(values)
end

end


if abspath(PROGRAM_FILE) == @__FILE__
    sample = [18.0, 20.0, 22.0]
    println("mean = ", F02JuliaArraysAndTests.mean_temperature(sample))
    println("anomaly = ", F02JuliaArraysAndTests.temperature_anomaly(sample))
end
