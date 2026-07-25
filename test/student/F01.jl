using Test

const F01_STUDENT_RUN = normpath(
    joinpath(@__DIR__, "..", "..", "exercises", "F01_first_pull_request", "run.jl"),
)
if !isdefined(Main, :F01FirstPullRequest)
    include(F01_STUDENT_RUN)
end

@testset "F01 student-authored examples" begin
    # TODO(F01): replace this smoke check with one greeting example of your own.
    @test isdefined(F01FirstPullRequest, :student_greeting)
end
