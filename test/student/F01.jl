using Test

const F01_STUDENT_RUN = normpath(
    joinpath(@__DIR__, "..", "..", "exercises", "F01_first_pull_request", "run.jl"),
)
if !isdefined(Main, :F01FirstPullRequest)
    include(F01_STUDENT_RUN)
end

@testset "F01 student-authored examples" begin
    # TODO(F01): この簡易確認を、自分で選んだ挨拶の例1件へ置き換える。
    @test isdefined(F01FirstPullRequest, :student_greeting)
end
