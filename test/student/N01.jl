using Test

const N01_STUDENT_RUN = normpath(joinpath(
    @__DIR__, "..", "..", "exercises", "N01_linear_advection", "run.jl",
))
if !isdefined(Main, :N01LinearAdvection)
    include(N01_STUDENT_RUN)
end

@testset "N01 student-authored representative case" begin
    # この一例を手計算し、入力・期待値・保証範囲を学習ログで説明する。
    u_old = [1.0, 2.0, 4.0, 8.0]
    u_new = similar(u_old)
    N01LinearAdvection.upwind_step!(u_new, u_old, 1.0, 0.25, 0.5)
    @test u_new == [1.0, 1.5, 3.0, 8.0]
end
