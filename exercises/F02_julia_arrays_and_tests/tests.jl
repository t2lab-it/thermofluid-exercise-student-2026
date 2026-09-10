using Test

if !isdefined(Main, :F02JuliaArraysAndTests)
    include(joinpath(@__DIR__, "run.jl"))
end

@testset "F02 必須テスト" begin
    # TODO(必須): 有限値の配列を一つ選び、mean_temperatureの平均とtemperature_anomalyの偏差配列を手計算した期待値で確かめる。
    @test false

    # TODO(必須): 上で選んだ配列の偏差の総和が丸め誤差の範囲で0になることを確かめる。許容誤差は根拠を持って選ぶ。
    @test false

    # TODO(必須): temperature_anomalyを呼んでも入力配列が変化しないことを、呼出し前のコピーと比較して確かめる。
    @test false

    # TODO(必須): 空配列、NaN、Infのいずれか一つを選び、対象APIがArgumentErrorとして拒否することを確かめる。
    @test false
end

@testset "F02 自作テスト" begin
    # TODO(自作): 戻り値の型、別の数学的性質、または必須とは異なる不正入力から一つ選び、入力と期待値を自分で書く。
    @test false
end
