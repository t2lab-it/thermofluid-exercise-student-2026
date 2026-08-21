using Test

const ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const GUIDE = "https://t2lab-it.github.io/thermofluid-exercise-2026/guides/ai-usage.html"
const LOGS = ("F01.md", "F02.md", "F03-F04.md", "N01.md")
const FIELDS = ("依頼内容（利用なしの場合は「利用なし」）", "重要な提案", "採用・修正・却下と理由")
const AI_SECTION = r"(?ms)^## AI利用[ \t]*\n(.*?)(?=^## |\z)"
const LEGACY = ("説明、エラー解説、練習問題", "新規セッションの全対話ログ", "個人情報・秘密情報を入力していないことの確認")
const PR_SAFETY = ("秘密情報", "個人情報", "成績情報", "非公開URL")
const PR_ADOPTION_HEADING = r"(?m)^## AI提案の採否[ \t]*$"

@testset "shared AI usage record contract" begin
    for name in LOGS
        source = read(joinpath(ROOT, "learning_logs", "templates", name), String)
        sections = collect(eachmatch(AI_SECTION, source))
        @test length(sections) == 1
        @test length(sections) == 1 && all(field -> occursin(field, only(sections).captures[1]), FIELDS)
        @test all(rule -> !occursin(rule, source), LEGACY)
    end
    @test !occursin(GUIDE, read(joinpath(ROOT, "README.md"), String))
    template = read(joinpath(ROOT, ".github", "pull_request_template.md"), String)
    @test occursin(GUIDE, template)
    @test occursin("学習ログ", template)
    @test all(word -> occursin(word, template), ("diff", "テスト", "数値結果"))
    @test all(word -> occursin(word, template), PR_SAFETY)
    @test length(collect(eachmatch(PR_ADOPTION_HEADING, template))) == 1
    @test !occursin("AIの提案を採用した箇所", template)
end
