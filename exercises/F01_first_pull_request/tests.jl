using Test

if !isdefined(Main, :F01FirstPullRequest)
    include(joinpath(@__DIR__, "run.jl"))
end

@testset "F01 必須テスト" begin
    # TODO(必須): student_greetingへ前後に空白を含む名前を渡し、空白を除いた完全な挨拶文字列になることを確かめる。入力と期待文字列は自分で書く。
    @test false

    # TODO(必須): student_greetingが空白だけの名前をArgumentErrorとして拒否することを確かめる。入力は自分で書く。
    @test false
end

@testset "F01 自作テスト" begin
    # TODO(自作): 必須テストとは異なる名前を一つ選び、期待する完全な挨拶文字列を自分で書く。
    @test false
end
