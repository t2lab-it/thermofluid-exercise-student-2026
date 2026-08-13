using Test

const F03_STUDENT_RUN =
    normpath(joinpath(@__DIR__, "..", "..", "exercises", "F03_vector_calculus", "run.jl"))
if !isdefined(Main, :F03VectorCalculus)
    include(F03_STUDENT_RUN)
end

@testset "F03 student-authored example" begin
    # STUDENT_TEST_REQUIRED(F03): (0.2,-0.3,0.4)とは異なる点を使い、
    # 勾配、回転、ラプラシアンを`automatic_reference`と比較する。
    @test true # この仮実装を、指定された独立な比較へ置き換える。
end
