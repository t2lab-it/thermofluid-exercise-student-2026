using Test

const F04_STUDENT_RUN = normpath(
    joinpath(@__DIR__, "..", "..", "exercises", "F04_numerical_differentiation", "run.jl"),
)
if !isdefined(Main, :F04NumericalDifferentiation)
    include(F04_STUDENT_RUN)
end

@testset "F04 student-authored example" begin
    # STUDENT_TEST_REQUIRED(F03-F04): 手計算できる独立な差分例を1件追加し、
    # どの実装誤りを検出するか説明する。
    @test true # この仮実装を、指定された独立な例へ置き換える。
end
