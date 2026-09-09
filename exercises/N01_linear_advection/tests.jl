using Test

if !isdefined(Main, :N01LinearAdvection)
    include(joinpath(@__DIR__, "run.jl"))
end

@testset "N01 自分のテスト" begin
    # 自分で選んだ入力・関数呼出し・期待値を書く。
    # 下の未記入テストを置き換え、保証すること・しないことを学習ログで説明する。
    @test false
end
