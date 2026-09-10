using Test

if !isdefined(Main, :F04NumericalDifferentiation)
    include(joinpath(@__DIR__, "run.jl"))
end

@testset "F03-F04 必須テスト" begin
    # TODO(必須): 二次関数、評価点、刻み幅を自分で選び、forward_difference、backward_difference、centered_differenceの三つを手計算した期待値で区別して確かめる。
    @test false

    # TODO(必須): 同じ滑らかな関数で刻み幅を半分にし、前進・後退・中心差分の誤差がそれぞれ理論どおりの収束次数を示すことを確かめる。期待値と許容範囲は自分で導く。
    @test false
end

@testset "F03-F04 自作テスト" begin
    # TODO(自作): 別の関数、評価点、または入力条件を選び、どの実装ミスを検出するか説明できるテストを一つ書く。F03単独の別テストは作らない。
    @test false
end
