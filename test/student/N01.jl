using Test

const N01_STUDENT_RUN =
    normpath(joinpath(@__DIR__, "..", "..", "exercises", "N01_linear_advection", "run.jl"))
if !isdefined(Main, :N01LinearAdvection)
    include(N01_STUDENT_RUN)
end

@testset "N01 student-authored representative case" begin
    # STUDENT_TEST_REQUIRED(N01): 手計算できる更新例または安定・不安定比較を
    # 一つ選び、入力、関数呼び出し、期待値を自分で書いてから次の行を置き換える。
    @test false
end
