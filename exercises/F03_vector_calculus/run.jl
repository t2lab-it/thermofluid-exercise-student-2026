module F03VectorCalculus

using ForwardDiff
using LinearAlgebra

export gradient_scalar, curl_vector, laplacian_scalar

scalar_field(point) = sin(point[1]) * cos(point[2]) * exp(point[3])

vector_field(point) = (
    sin(point[2]) * exp(point[3]),
    sin(point[3]) * exp(point[1]),
    sin(point[1]) * exp(point[2]),
)

function validate_point(point)
    point isa Tuple && length(point) == 3 ||
        throw(ArgumentError("point must be a three-element tuple"))
    all(value -> value isa Real && isfinite(value), point) ||
        throw(ArgumentError("point coordinates must be finite real values"))
    nothing
end

function gradient_scalar(point)
    validate_point(point)
    # TODO(F03): return the three analytic components of grad(phi).
    value = zero(float(point[1] + point[2] + point[3]))
    (value, value, value)
end

function curl_vector(point)
    validate_point(point)
    # TODO(F03): return the three analytic components of curl(A).
    value = zero(float(point[1] + point[2] + point[3]))
    (value, value, value)
end

function laplacian_scalar(point)
    validate_point(point)
    # TODO(F03): return the analytic scalar Laplacian of phi.
    zero(float(point[1] + point[2] + point[3]))
end

function automatic_reference(point)
    validate_point(point)
    values = collect(float.(point))
    gradient = Tuple(ForwardDiff.gradient(scalar_field, values))
    jacobian = ForwardDiff.jacobian(p -> collect(vector_field(p)), values)
    curl = (
        jacobian[3, 2] - jacobian[2, 3],
        jacobian[1, 3] - jacobian[3, 1],
        jacobian[2, 1] - jacobian[1, 2],
    )
    hessian = ForwardDiff.hessian(scalar_field, values)
    (; gradient, curl, laplacian = tr(hessian))
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    reference_point = (0.2, -0.3, 0.4)
    reference = F03VectorCalculus.automatic_reference(reference_point)
    reference_errors = (
        gradient = F03VectorCalculus.LinearAlgebra.norm(
            collect(reference.gradient) -
            collect(F03VectorCalculus.gradient_scalar(reference_point)),
            Inf,
        ),
        curl = F03VectorCalculus.LinearAlgebra.norm(
            collect(reference.curl) -
            collect(F03VectorCalculus.curl_vector(reference_point)),
            Inf,
        ),
        laplacian = abs(
            reference.laplacian - F03VectorCalculus.laplacian_scalar(reference_point),
        ),
    )
    println("ForwardDiff reference errors = ", reference_errors)
end
