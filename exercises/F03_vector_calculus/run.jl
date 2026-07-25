module F03VectorCalculus

export centered_partial, curl_gradient_residual, divergence_curl_residual,
    laplacian_identity_residual, verify_identities

scalar_field(point) = sin(point[1]) * cos(point[2]) * exp(point[3])

gradient_scalar(point) = (
    cos(point[1]) * cos(point[2]) * exp(point[3]),
    -sin(point[1]) * sin(point[2]) * exp(point[3]),
    sin(point[1]) * cos(point[2]) * exp(point[3]),
)

vector_field(point) = (
    sin(point[2]) * exp(point[3]),
    sin(point[3]) * exp(point[1]),
    sin(point[1]) * exp(point[2]),
)

curl_vector(point) = (
    sin(point[1]) * exp(point[2]) - cos(point[3]) * exp(point[1]),
    sin(point[2]) * exp(point[3]) - cos(point[1]) * exp(point[2]),
    sin(point[3]) * exp(point[1]) - cos(point[2]) * exp(point[3]),
)

laplacian_scalar(point) = -scalar_field(point)

function validate_point(point)
    point isa Tuple && length(point) == 3 ||
        throw(ArgumentError("point must be a three-element tuple"))
    all(value -> value isa Real && isfinite(value), point) ||
        throw(ArgumentError("point coordinates must be finite real values"))
    nothing
end

function validate_spacing(h::Real)
    isfinite(h) && h > 0 || throw(ArgumentError("h must be finite and positive"))
    nothing
end

function centered_partial(f, point, axis::Integer, h::Real)
    validate_point(point)
    validate_spacing(h)
    axis isa Bool && throw(ArgumentError("axis must be 1, 2, or 3, not Bool"))
    axis in 1:3 || throw(ArgumentError("axis must be 1, 2, or 3"))

    # TODO(F03): evaluate f at point ± h in the selected coordinate.
    zero(float(f(point)))
end

function curl_gradient_residual(point, h::Real)
    validate_point(point)
    validate_spacing(h)

    # TODO(F03): assemble the three components of curl(grad(phi)).
    value = zero(float(point[1] + point[2] + point[3] + h))
    (value, value, value)
end

function divergence_curl_residual(point, h::Real)
    validate_point(point)
    validate_spacing(h)

    # TODO(F03): sum the three diagonal derivatives of curl(A).
    zero(float(point[1] + point[2] + point[3] + h))
end

function laplacian_identity_residual(point, h::Real)
    validate_point(point)
    validate_spacing(h)

    # TODO(F03): subtract the analytic Laplacian from div(grad(phi)).
    zero(float(point[1] + point[2] + point[3] + h))
end

function verify_identities(n::Integer)
    n isa Bool && throw(ArgumentError("n must be an odd integer of at least 5"))
    n >= 5 && isodd(n) || throw(ArgumentError("n must be an odd integer of at least 5"))

    coordinates = range(-1.0, 1.0; length=Int(n))
    h = step(coordinates)
    curl_gradient = 0.0
    divergence_curl = 0.0
    laplacian_identity = 0.0

    for x in coordinates[2:(end - 1)]
        for y in coordinates[2:(end - 1)]
            for z in coordinates[2:(end - 1)]
                point = (x, y, z)
                curl_gradient = max(
                    curl_gradient,
                    maximum(abs, curl_gradient_residual(point, h)),
                )
                divergence_curl = max(
                    divergence_curl,
                    abs(divergence_curl_residual(point, h)),
                )
                laplacian_identity = max(
                    laplacian_identity,
                    abs(laplacian_identity_residual(point, h)),
                )
            end
        end
    end

    (
        curl_gradient=curl_gradient,
        divergence_curl=divergence_curl,
        laplacian_identity=laplacian_identity,
    )
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    coarse = F03VectorCalculus.verify_identities(9)
    fine = F03VectorCalculus.verify_identities(17)
    ratios = (
        curl_gradient=iszero(fine.curl_gradient) ? Inf :
            coarse.curl_gradient / fine.curl_gradient,
        divergence_curl=iszero(fine.divergence_curl) ? Inf :
            coarse.divergence_curl / fine.divergence_curl,
        laplacian_identity=iszero(fine.laplacian_identity) ? Inf :
            coarse.laplacian_identity / fine.laplacian_identity,
    )
    println("coarse (n=9) = ", coarse)
    println("fine (n=17) = ", fine)
    println("coarse/fine ratios = ", ratios)
end
