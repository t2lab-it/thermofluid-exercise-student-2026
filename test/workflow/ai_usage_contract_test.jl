using Test

const ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const GUIDE = "https://t2lab-it.github.io/thermofluid-exercise-2026/guides/ai-usage.html"
const LOGS = ("F01.md", "F02.md", "F03.md", "F04.md", "N01.md")
const FIELDS = ("依頼内容（利用なしの場合は「利用なし」）", "重要な提案", "採用・修正・却下と理由")
const LEGACY = ("説明、エラー解説、練習問題", "新規セッションの全対話ログ", "個人情報・秘密情報を入力していないことの確認")

@testset "shared AI usage record contract" begin
    for name in LOGS
        source = read(joinpath(ROOT, "learning_logs", "templates", name), String)
        @test occursin(r"(?m)^## AI利用\s*$", source)
        @test all(field -> occursin(field, source), FIELDS)
        @test all(rule -> !occursin(rule, source), LEGACY)
    end
    @test occursin(GUIDE, read(joinpath(ROOT, "README.md"), String))
    template = read(joinpath(ROOT, ".github", "pull_request_template.md"), String)
    @test occursin(GUIDE, template)
    @test occursin("Learning log", template)
    @test all(word -> occursin(word, template), ("private URL", "diff", "テスト", "数値結果"))
    @test !occursin("AIの提案を採用した箇所", template)
end
